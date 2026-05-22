defmodule Wafer.InterruptRegistry do
  alias Wafer.{Conn, GPIO}
  alias __MODULE__, as: IR
  import Wafer.Guards

  @moduledoc """
  This module provides Wafer's interrupt registry.  This allows multiple
  subscribers to be subscribed to interrupts from many different pins.

  It is used by `Driver.Circuits.GPIO.Dispatcher` and you should probably use it
  if you're writing your own driver which supports sending interrupts to
  subscribers.

  ## Internals

  The underlying `Registry` uses `{key, :rising}` and `{key, :falling}` as its
  keys.  Subscribing with `:both` simply registers the caller under both keys,
  so publishing an edge is a plain registry dispatch — no filtering or match
  specs required.
  """

  @type key :: any

  @doc """
  Subscribe the calling process to interrupts for the specified `pin_condition`
  using the provided `key`.

  See `subscribe/4` for more information.

  ## Example

      iex> subscribe({MCP230017.Pin, 13}, :rising, conn)
      :ok
  """
  @spec subscribe(key, GPIO.pin_condition(), Conn.t()) :: :ok
  def subscribe(key, pin_condition, conn)
      when is_pin_condition(pin_condition),
      do: subscribe(key, pin_condition, conn, nil)

  @doc """
  Subscribe the calling process to interrupts for the specified `pin_condition`
  using the provided `key`.

  ## Arguments
    - `key` a key which uniquely describes the pin.  Probably a combination of
      device name and pin.
    - `pin_condition` either `:rising`, `:falling` or `:both`.  Subscribing with
      `:both` is equivalent to subscribing with `:rising` and `:falling`
      separately.
    - `conn` the receiver's connection to the pin, sent back to them in the
      interrupt message.
    - `metadata` arbitrary data which will be sent to the receiver process in
      the interrupt message. Defaults to `nil`.
  """
  @spec subscribe(key, GPIO.pin_condition(), Conn.t(), any) :: :ok
  def subscribe(key, :both, conn, metadata) do
    :ok = subscribe(key, :rising, conn, metadata)
    :ok = subscribe(key, :falling, conn, metadata)
    :ok
  end

  def subscribe(key, pin_condition, conn, metadata)
      when pin_condition in [:rising, :falling] do
    {:ok, _} = Registry.register(IR, {key, pin_condition}, {conn, metadata})
    :ok
  end

  @doc """
  Remove all subscriptions for `key`, `pin_condition` and `conn`.

  Unsubscribing with `:both` removes the caller's subscription from both the
  `:rising` and `:falling` buckets.
  """
  @spec unsubscribe(key, GPIO.pin_condition(), Conn.t()) :: :ok
  def unsubscribe(key, :both, conn) do
    :ok = unsubscribe(key, :rising, conn)
    :ok = unsubscribe(key, :falling, conn)
    :ok
  end

  def unsubscribe(key, pin_condition, conn) when pin_condition in [:rising, :falling] do
    Registry.unregister_match(IR, {key, pin_condition}, {conn, :_})
    :ok
  end

  @doc """
  Returns a list of all subscriptions to `key`.

  A subscriber who subscribed with `:both` is returned as two entries — one
  per edge.
  """
  @spec subscriptions(key) :: [{GPIO.pin_condition(), Conn.t(), metadata :: any, receiver :: pid}]
  def subscriptions(key), do: subscriptions(key, :rising) ++ subscriptions(key, :falling)

  @doc """
  Returns a list of all subscriptions for `key` and `pin_condition`.

  Subscribers who subscribed with `:both` appear in the lists for both
  `:rising` and `:falling`.  Calling with `:both` returns the same as
  `subscriptions/1`.
  """
  @spec subscriptions(key, GPIO.pin_condition()) :: [
          {GPIO.pin_condition(), Conn.t(), metadata :: any, receiver :: pid}
        ]
  def subscriptions(key, :both), do: subscriptions(key)

  def subscriptions(key, pin_condition) when pin_condition in [:rising, :falling] do
    IR
    |> Registry.lookup({key, pin_condition})
    |> Enum.map(fn {pid, {conn, metadata}} -> {pin_condition, conn, metadata, pid} end)
  end

  @doc """
  Count the number of active subscriptions for `key`.

  A subscriber who subscribed with `:both` is counted twice.
  """
  @spec count_subscriptions(key) :: non_neg_integer
  def count_subscriptions(key),
    do: count_subscriptions(key, :rising) + count_subscriptions(key, :falling)

  @doc """
  Count the number of active subscriptions for `key` and `pin_condition`.

  Subscribers who subscribed with `:both` contribute to both counts.
  """
  @spec count_subscriptions(key, GPIO.pin_condition()) :: non_neg_integer
  def count_subscriptions(key, :both), do: count_subscriptions(key)

  def count_subscriptions(key, pin_condition) when pin_condition in [:rising, :falling],
    do: Registry.count_match(IR, {key, pin_condition}, :_)

  @doc """
  Are there any subscribers to `key`?
  """
  @spec subscribers?(key) :: boolean
  def subscribers?(key), do: count_subscriptions(key) > 0

  @doc """
  Are there any subscribers to `key` and `pin_condition`?
  """
  @spec subscribers?(key, GPIO.pin_condition()) :: boolean
  def subscribers?(key, pin_condition) when is_pin_condition(pin_condition),
    do: count_subscriptions(key, pin_condition) > 0

  @doc """
  Publish an interrupt to subscribers that are interested in `key` and
  `pin_condition`.

  The interrupt message takes the form
  `{:interrupt, Conn.t(), :rising | :falling, metadata :: any}`.
  """
  @spec publish(key, :rising | :falling) :: {:ok, non_neg_integer}
  def publish(key, pin_condition) when pin_condition in [:rising, :falling] do
    entries = Registry.lookup(IR, {key, pin_condition})

    Enum.each(entries, fn {pid, {conn, metadata}} ->
      send(pid, {:interrupt, conn, pin_condition, metadata})
    end)

    {:ok, length(entries)}
  end
end
