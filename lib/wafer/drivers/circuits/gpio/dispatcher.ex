defmodule Wafer.Driver.Circuits.GPIO.Dispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.{Conn, GPIO, InterruptRegistry}
  import Wafer.Guards

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `Circuits.GPIO`.

  Because the Circuits' interrupt doesn't provide an indication of whether the
  pin is rising or falling we store the last known pin state and use it to
  compare.

  Each open `ref` can only have a single hardware interrupt trigger at a time,
  so the dispatcher tracks how many enables are currently outstanding for each
  edge on each ref and arms the hardware with the union.  Sequential calls of
  `enable(conn, :rising)` and `enable(conn, :falling)` therefore leave the
  ref armed for `:both`, not just the last-requested edge.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: Dispatcher)

  @doc """
  Enable interrupts for this connection using the specified pin_condition.

  The caller is registered as a subscriber before the hardware interrupt is
  armed, so any edge that fires after arming is guaranteed to find a
  subscriber in the registry.
  """
  @spec enable(Conn.t(), GPIO.pin_condition(), any) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(%{pin: pin} = conn, pin_condition, metadata \\ nil)
      when is_pin_condition(pin_condition) do
    :ok = InterruptRegistry.subscribe(key(pin), pin_condition, conn, metadata)

    case GenServer.call(Dispatcher, {:enable, conn, pin_condition}) do
      {:ok, conn} ->
        {:ok, conn}

      {:error, reason} ->
        :ok = InterruptRegistry.unsubscribe(key(pin), pin_condition, conn)
        {:error, reason}
    end
  end

  @doc """
  Disable interrupts for this connection using the specified pin_condition.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(%{pin: pin} = conn, pin_condition) when is_pin_condition(pin_condition) do
    with :ok <- InterruptRegistry.unsubscribe(key(pin), pin_condition, conn) do
      GenServer.call(Dispatcher, {:disable, conn, pin_condition})
    end
  end

  @impl true
  def init(_opts), do: {:ok, %{values: %{}, triggers: %{}}}

  @impl true
  def handle_call(
        {:enable, %{pin: pin, ref: ref} = conn, pin_condition},
        _from,
        %{values: values, triggers: triggers} = state
      )
      when is_pin_condition(pin_condition) and is_pin_number(pin) do
    values = Map.put_new_lazy(values, pin, fn -> Wrapper.read(ref) end)
    triggers = adjust_triggers(triggers, ref, pin_condition, +1)

    case Wrapper.set_interrupts(ref, hw_trigger(triggers, ref)) do
      :ok -> {:reply, {:ok, conn}, %{state | values: values, triggers: triggers}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(
        {:disable, %{pin: pin, ref: ref} = conn, pin_condition},
        _from,
        %{values: values, triggers: triggers} = state
      )
      when is_pin_number(pin) and is_pin_condition(pin_condition) do
    triggers = adjust_triggers(triggers, ref, pin_condition, -1)

    case Wrapper.set_interrupts(ref, hw_trigger(triggers, ref)) do
      :ok ->
        values =
          if InterruptRegistry.subscribers?(key(pin)),
            do: values,
            else: Map.delete(values, pin)

        {:reply, {:ok, conn}, %{state | values: values, triggers: triggers}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(
        {:circuits_gpio, pin, _timestamp, value},
        %{values: values} = state
      )
      when is_pin_number(pin) and is_pin_value(value) do
    last_value = Map.get(values, pin)
    maybe_publish(key(pin), last_value, value)
    {:noreply, %{state | values: Map.put(values, pin, value)}}
  end

  defp key(pin), do: {__MODULE__, pin}

  defp maybe_publish(key, 0, 1), do: InterruptRegistry.publish(key, :rising)
  defp maybe_publish(key, 1, 0), do: InterruptRegistry.publish(key, :falling)
  defp maybe_publish(_key, _, _), do: :ignore

  defp adjust_triggers(triggers, ref, pin_condition, delta) do
    counts = Map.get(triggers, ref, %{rising: 0, falling: 0})

    counts =
      pin_condition
      |> edges()
      |> Enum.reduce(counts, fn edge, acc ->
        Map.update!(acc, edge, &max(&1 + delta, 0))
      end)

    if counts == %{rising: 0, falling: 0} do
      Map.delete(triggers, ref)
    else
      Map.put(triggers, ref, counts)
    end
  end

  defp edges(:rising), do: [:rising]
  defp edges(:falling), do: [:falling]
  defp edges(:both), do: [:rising, :falling]

  defp hw_trigger(triggers, ref) do
    case Map.get(triggers, ref) do
      %{rising: r, falling: f} when r > 0 and f > 0 -> :both
      %{rising: r} when r > 0 -> :rising
      %{falling: f} when f > 0 -> :falling
      _ -> :none
    end
  end
end
