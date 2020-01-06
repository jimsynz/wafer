defmodule Wafer.InterruptRegistry do
  alias Wafer.{Conn, GPIO}
  alias __MODULE__, as: IR
  import Wafer.Guards

  @moduledoc """
  This module provides Wafer's interrupt registry.  This allows multiple
  subscribers to be subscribed to interrupts from many different pins.

  It is used by `Driver.CircuitsGPIODispatcher` and
  `Driver.ElixirALEGPIODispatcher` and you should probably use it if you're
  writing your own driver which supports sending interrupts to subscribers.
  """

  @type key :: any

  @doc """
  Subscribe the calling process to interrupts for the specified `pin_condition`
  using the provided `key`.

  See `subscribe/5` for more information.

  ## Example

      iex> subscribe({MCP230017.Pin, 13}, :rising, conn)
      :ok
  """
  @spec subscribe(key, GPIO.pin_condition(), Conn.t()) :: :ok
  def subscribe(key, pin_condition, conn) when is_pin_condition(pin_condition),
    do: subscribe(key, pin_condition, conn, nil, self())

  @doc """
  Subscribe `receiver` process to interrupts for the specified `pin_condition`
  using the provided `key`.

  See `subscribe/5` for more information.

  ## Example

      iex> subscribe({MCP230017.Pin, 13}, :rising, conn, self())
      :ok
  """
  @spec subscribe(key, GPIO.pin_condition(), Conn.t(), pid) :: :ok
  def subscribe(key, pin_condition, conn, receiver)
      when is_pin_condition(pin_condition)
      when is_pid(receiver),
      do: subscribe(key, pin_condition, conn, nil, receiver)

  @doc """
  Subscribe `receiver` process to interrupts for the specified `pin_condition`
  using the provided `key`.

  ## Arguments
    - `key` a key which uniquely describes the pin.  Probably a combination of
      device name and pin.
    - `pin_condition` either `:rising`, `:falling` or `:both`.
    - `conn` the receiver's connection to the pin, sent back to them in the
      interrupt message.
    - `metadata` arbitrary data which will be sent to the receiver process in
      the interrupt message. Defaults to `nil`.
  """
  @spec subscribe(key, GPIO.pin_condition(), Conn.t(), any, pid) :: :ok
  def subscribe(key, :rising = _pin_condition, conn, metadata, receiver) when is_pid(receiver) do
    with :yes <- Registry.register_name({IR, key, {:rising, conn, metadata}}, self()), do: :ok
  end

  def subscribe(key, :falling = _pin_condition, conn, metadata, receiver) when is_pid(receiver) do
    with :yes <- Registry.register_name({IR, key, {:falling, conn, metadata}}, self()), do: :ok
  end

  def subscribe(key, :both = _pin_condition, conn, metadata, receiver) when is_pid(receiver) do
    with :yes <- Registry.register_name({IR, key, {:both, conn, metadata}}, self()), do: :ok
  end

  @doc """
  Remove all subscriptions for `key`, `pin_condition` and `conn`.
  """
  @spec unsubscribe(key, GPIO.pin_condition(), Conn.t()) :: :ok
  def unsubscribe(key, :rising = _pin_condition, conn),
    do: Registry.unregister_match(IR, key, {:rising, conn, :_})

  def unsubscribe(key, :falling = _pin_condition, conn),
    do: Registry.unregister_match(IR, key, {:falling, conn, :_})

  def unsubscribe(key, :both = _pin_condition, conn),
    do: Registry.unregister_match(IR, key, {:both, conn, :_})

  @doc """
  Returns a list of all subscriptions to `key`.
  """
  @spec subscriptions(key) :: [{GPIO.pin_condition(), Conn.t(), metadata :: any, receiver :: pid}]
  def subscriptions(key) do
    IR
    |> Registry.match(key, :"$1")
    |> Enum.map(fn {pid, {condition, conn, metadata}} -> {condition, conn, metadata, pid} end)
  end

  @doc """
  Returns a list of all subscriptions `key` and `pin_condition`.
  """
  @spec subscriptions(key, GPIO.pin_condition()) :: [
          {GPIO.pin_condition(), Conn.t(), metadata :: any, receiver :: pid}
        ]
  def subscriptions(key, pin_condition) when is_pin_condition(pin_condition) do
    IR
    |> Registry.match(key, {pin_condition, :"$1", :"$2"})
    |> Enum.map(fn {pid, {condition, conn, metadata}} -> {condition, conn, metadata, pid} end)
  end

  @doc """
  Count the number of active subscriptions for `key`.
  """
  @spec count_subscriptions(key) :: non_neg_integer
  def count_subscriptions(key), do: Registry.count_match(IR, key, :_)

  @doc """
  Count the number of active subscriptions for `key` and `pin_condition`.
  """
  @spec count_subscriptions(key, GPIO.pin_condition()) :: non_neg_integer
  def count_subscriptions(key, pin_condition) when is_pin_condition(pin_condition),
    do: Registry.count_match(IR, key, {pin_condition, :_, :_})

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

  Searches the registry for all subscribers to are subscribed to `pin_condition`
  or `:both` and publishes the interrupt message to them.  The interrupt message
  takes the form `{:interrupt, Conn.t(), :rising | :falling, metadata :: any}`.
  """
  @spec publish(key, :rising | :falling) :: {:ok, non_neg_integer}
  def publish(key, pin_condition) when pin_condition in ~w[rising falling]a do
    count =
      IR
      |> Registry.match(key, {:"$1", :"$2", :"$3"}, [
        {:or, {:==, :"$1", pin_condition}, {:==, :"$1", :both}}
      ])
      |> Enum.map(fn {pid, {_condition, conn, metadata}} ->
        send(pid, {:interrupt, conn, pin_condition, metadata})
      end)
      |> Enum.count()

    {:ok, count}
  end
end
