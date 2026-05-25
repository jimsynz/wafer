defmodule Wafer.Driver.Circuits.GPIO.Dispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.{Conn, GPIO, InterruptRegistry}
  import Wafer.Guards
  require Logger

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

  ## Backends that emit a different `gpio_spec` form than was passed to `open/3`

  `Circuits.GPIO` documents that the `gpio_spec` element of an interrupt
  message equals the spec passed to `open/3`, but some backends (for example
  `circuits_ft232h`'s GPIO poller) emit a different normalised form. The
  dispatcher learns every spec form a `ref` may appear under at enable time —
  by consulting `Circuits.GPIO.identifiers/1` — so interrupts are matched
  back to the originating `conn` regardless of which form the backend chose.
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
  def init(_opts),
    do: {:ok, %{values: %{}, triggers: %{}, ref_by_spec: %{}, pin_by_ref: %{}}}

  @impl true
  def handle_call(
        {:enable, %{pin: pin, ref: ref} = conn, pin_condition},
        _from,
        state
      )
      when is_pin_condition(pin_condition) do
    values = Map.put_new_lazy(state.values, ref, fn -> Wrapper.read(ref) end)
    triggers = adjust_triggers(state.triggers, ref, pin_condition, +1)
    ref_by_spec = learn_aliases(state.ref_by_spec, pin, ref)
    pin_by_ref = Map.put(state.pin_by_ref, ref, pin)

    case Wrapper.set_interrupts(ref, hw_trigger(triggers, ref)) do
      :ok ->
        {:reply, {:ok, conn},
         %{
           state
           | values: values,
             triggers: triggers,
             ref_by_spec: ref_by_spec,
             pin_by_ref: pin_by_ref
         }}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(
        {:disable, %{pin: pin, ref: ref} = conn, pin_condition},
        _from,
        state
      )
      when is_pin_condition(pin_condition) do
    triggers = adjust_triggers(state.triggers, ref, pin_condition, -1)

    case Wrapper.set_interrupts(ref, hw_trigger(triggers, ref)) do
      :ok ->
        new_state =
          if InterruptRegistry.subscribers?(key(pin)) do
            %{state | triggers: triggers}
          else
            %{
              state
              | triggers: triggers,
                values: Map.delete(state.values, ref),
                pin_by_ref: Map.delete(state.pin_by_ref, ref),
                ref_by_spec: drop_aliases_for(state.ref_by_spec, ref)
            }
          end

        {:reply, {:ok, conn}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info({:circuits_gpio, spec, _timestamp, value}, state)
      when is_pin_value(value) do
    case Map.fetch(state.ref_by_spec, spec) do
      {:ok, ref} ->
        pin = Map.fetch!(state.pin_by_ref, ref)
        last_value = Map.get(state.values, ref)
        maybe_publish(key(pin), last_value, value)
        {:noreply, %{state | values: Map.put(state.values, ref, value)}}

      :error ->
        Logger.debug(fn ->
          "Wafer.Driver.Circuits.GPIO.Dispatcher: ignoring interrupt for unknown gpio_spec " <>
            inspect(spec)
        end)

        {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

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

  defp learn_aliases(ref_by_spec, pin, ref) do
    pin
    |> spec_aliases()
    |> Enum.reduce(ref_by_spec, &Map.put(&2, &1, ref))
  end

  defp spec_aliases(pin) do
    extras =
      case safe_identifiers(pin) do
        {:ok, %{} = identifiers} ->
          [
            Map.get(identifiers, :location),
            Map.get(identifiers, :label),
            with c when not is_nil(c) <- Map.get(identifiers, :controller),
                 l when not is_nil(l) <- Map.get(identifiers, :label) do
              {c, l}
            else
              _ -> nil
            end
          ]

        _ ->
          []
      end

    [pin | extras]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp safe_identifiers(pin) do
    Wrapper.identifiers(pin)
  rescue
    _ -> :error
  catch
    _, _ -> :error
  end

  defp drop_aliases_for(ref_by_spec, ref) do
    ref_by_spec
    |> Enum.reject(fn {_spec, r} -> r == ref end)
    |> Map.new()
  end
end
