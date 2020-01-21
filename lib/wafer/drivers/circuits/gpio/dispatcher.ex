defmodule Wafer.Driver.Circuits.GPIO.Dispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.{Conn, GPIO, InterruptRegistry}
  import Wafer.Guards

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `Circuits.GPIO`.

  Because the Circuit's interrupt doesn't provide an indication of whether the
  pin is rising or falling we store the last known pin state and use it to
  compare.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: Dispatcher)

  @doc """
  Enable interrupts for this connection using the specified pin_condition.
  """
  @spec enable(Conn.t(), GPIO.pin_condition(), any) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(%{pin: pin} = conn, pin_condition, metadata \\ nil)
      when is_pin_condition(pin_condition) do
    with {:ok, conn} <- GenServer.call(Dispatcher, {:enable, conn, pin_condition}),
         :ok <- InterruptRegistry.subscribe(key(pin), pin_condition, conn, metadata) do
      {:ok, conn}
    end
  end

  @doc """
  Disable interrupts for this connection using the specified pin_condition.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_condition) when is_pin_condition(pin_condition),
    do: GenServer.call(Dispatcher, {:disable, conn, pin_condition})

  @impl true
  def init(_opts) do
    {:ok, %{values: %{}}}
  end

  @impl true
  def handle_call(
        {:enable, %{pin: pin, ref: ref} = conn, pin_condition},
        _from,
        state
      )
      when is_pin_condition(pin_condition) and is_reference(ref) and is_pin_number(pin) do
    case Wrapper.set_interrupts(ref, pin_condition) do
      :ok -> {:reply, {:ok, conn}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:disable, %{pin: pin} = conn, pin_condition}, _from, %{values: values} = state)
      when is_pin_number(pin) and is_pin_condition(pin_condition) do
    key = key(pin)
    :ok = InterruptRegistry.unsubscribe(key, pin_condition, conn)

    values = if InterruptRegistry.subscribers?(key), do: values, else: Map.delete(values, pin)
    {:reply, {:ok, conn}, %{state | values: values}}
  end

  @impl true
  def handle_info(
        {:circuits_gpio, pin, _timestamp, value},
        %{values: values} = state
      )
      when is_pin_number(pin) and is_pin_value(value) do
    last_value = Map.get(values, pin, nil)
    maybe_publish(key(pin), last_value, value)
    {:noreply, %{state | values: Map.put(values, pin, value)}}
  end

  defp key(pin), do: {__MODULE__, pin}

  defp maybe_publish(key, nil, 1), do: InterruptRegistry.publish(key, :rising)
  defp maybe_publish(key, 0, 1), do: InterruptRegistry.publish(key, :rising)
  defp maybe_publish(key, nil, 0), do: InterruptRegistry.publish(key, :falling)
  defp maybe_publish(key, 1, 0), do: InterruptRegistry.publish(key, :falling)
  defp maybe_publish(_key, _, _), do: :ignore
end
