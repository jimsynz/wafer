defmodule Wafer.Driver.CircuitsGPIODispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.{Conn, GPIO, InterruptRegistry}
  alias Circuit.GPIO, as: Driver

  @allowed_triggers ~w[rising falling both]a

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `Circuits.GPIO`.
  """

  @doc false
  def start_link(opts), do: GenServer.start_link(__MODULE__, [opts], name: CircuitsGPIODispatcher)

  @doc """
  Enable interrupts for this connection using the specified trigger.
  """
  @spec enable(Conn.t(), GPIO.pin_trigger()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(conn, pin_trigger) when pin_trigger in @allowed_triggers,
    do: GenServer.call(CircuitsGPIODispatcher, {:enable, conn, pin_trigger})

  @doc """
  Disable interrupts for this connection using the specified trigger.
  """
  @spec disable(Conn.t(), GPIO.pin_trigger()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_trigger) when pin_trigger in @allowed_triggers,
    do: GenServer.call(CircuitsGPIODispatcher, {:disable, conn, pin_trigger})

  @impl true
  def init(_opts) do
    {:ok, %{subscriptions: %{}, values: %{}}}
  end

  @impl true
  def handle_call(
        {:enable, %{pin: pin, ref: ref} = conn, pin_trigger},
        _from,
        %{subscriptions: subscriptions} = state
      )
      when pin_trigger in @allowed_triggers do
    subscription = {conn, pin_trigger}

    subscriptions =
      subscriptions
      |> Map.update(pin, MapSet.new([subscription]), &MapSet.put(&1, subscription))

    case Driver.set_interrupts(ref, pin_trigger) do
      :ok ->
        {:reply, {:ok, conn}, %{state | subscriptions: subscriptions}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(
        {:disable, %{pin: pin} = conn, pin_trigger},
        _from,
        %{subscriptions: subscriptions, values: values} = state
      )
      when pin_trigger in @allowed_triggers do
    subscription = {conn, pin_trigger}

    pin_subscriptions =
      subscriptions
      |> Map.get(pin, MapSet.new())
      |> MapSet.delete(subscription)

    subscriptions =
      subscriptions
      |> Map.put(pin, pin_subscriptions)

    values = if Enum.empty?(pin_subscriptions), do: Map.delete(values, pin), else: values

    {:reply, {:ok, conn}, %{state | values: values, subscriptions: subscriptions}}
  end

  @impl true
  def handle_info(
        {:circuits_gpio, pin, _timestamp, value},
        %{subscriptions: subscriptions, values: values} = state
      ) do
    last_value = Map.get(values, pin, nil)

    on_condition_change(last_value, value, fn condition ->
      subscriptions
      |> Map.get(pin, [])
      |> Stream.filter(fn
        {_conn, ^condition} -> true
        {_conn, :both} -> true
        _ -> false
      end)
      |> Enum.each(fn {conn, _} = registry_key ->
        Registry.dispatch(InterruptRegistry, registry_key, fn pids ->
          for {pid, _} <- pids do
            send(pid, {:interrupt, conn, condition})
          end
        end)
      end)
    end)

    {:noreply, %{state | values: Map.put(values, pin, value)}}
  end

  defp on_condition_change(0, 1, callback), do: callback.(:rising)
  defp on_condition_change(1, 0, callback), do: callback.(:falling)
  defp on_condition_change(nil, 1, callback), do: callback.(:rising)
  defp on_condition_change(nil, 0, callback), do: callback.(:falling)
  defp on_condition_change(_, _, _), do: :no_change
end
