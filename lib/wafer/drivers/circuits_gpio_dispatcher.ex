defmodule Wafer.Driver.CircuitsGPIODispatcher do
  use GenServer
  alias __MODULE__
  alias Circuits.GPIO, as: Driver
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
  def start_link(opts), do: GenServer.start_link(__MODULE__, [opts], name: CircuitsGPIODispatcher)

  @doc """
  Enable interrupts for this connection using the specified trigger.
  """
  @spec enable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(conn, pin_condition) when is_pin_condition(pin_condition),
    do: GenServer.call(CircuitsGPIODispatcher, {:enable, conn, pin_condition, self()})

  @doc """
  Disable interrupts for this connection using the specified trigger.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_condition) when is_pin_condition(pin_condition),
    do: GenServer.call(CircuitsGPIODispatcher, {:disable, conn, pin_condition})

  @impl true
  def init(_opts) do
    {:ok, %{values: %{}}}
  end

  @impl true
  def handle_call({:enable, %{pin: pin, ref: ref} = conn, pin_condition, receiver}, _from, state)
      when is_pin_condition(pin_condition) and is_pid(receiver) and is_reference(ref) and
             is_pin_number(pin) do
    case Driver.set_interrupts(ref, pin_condition) do
      :ok ->
        subscribe(pin, pin_condition, conn, receiver)
        {:reply, {:ok, conn}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:disable, %{pin: pin} = conn, pin_condition}, _from, %{values: values} = state)
      when is_pin_number(pin) and is_pin_condition(pin_condition) do
    unsubscribe(pin, pin_condition, conn)

    values = if any_pin_subs?(pin), do: values, else: Map.delete(values, pin)

    {:reply, {:ok, conn}, %{state | values: values}}
  end

  @impl true
  def handle_info(
        {:circuits_gpio, pin, _timestamp, value},
        %{values: values} = state
      )
      when is_pin_number(pin) and is_pin_value(value) do
    last_value = Map.get(values, pin, nil)

    on_condition_change(last_value, value, fn condition ->
      Registry.dispatch(InterruptRegistry, {__MODULE__, pin, condition}, fn subs ->
        for {pid, conn} <- subs do
          send(pid, {:interrupt, conn, condition})
        end
      end)
    end)

    {:noreply, %{state | values: Map.put(values, pin, value)}}
  end

  defp on_condition_change(0, 1, callback), do: callback.(:rising)
  defp on_condition_change(1, 0, callback), do: callback.(:falling)
  defp on_condition_change(nil, 1, callback), do: callback.(:rising)
  defp on_condition_change(nil, 0, callback), do: callback.(:falling)
  defp on_condition_change(_, _, _), do: :no_change

  defp subscribe(pin, :rising, conn, receiver),
    do:
      Registry.register_name(
        {InterruptRegistry, {__MODULE__, pin, :rising}, conn},
        receiver
      )

  defp subscribe(pin, :falling, conn, receiver),
    do:
      Registry.register_name(
        {InterruptRegistry, {__MODULE__, pin, :falling}, conn},
        receiver
      )

  defp subscribe(pin, :both, conn, receiver) do
    Registry.register_name(
      {InterruptRegistry, {__MODULE__, pin, :rising}, conn},
      receiver
    )

    Registry.register_name(
      {InterruptRegistry, {__MODULE__, pin, :falling}, conn},
      receiver
    )
  end

  defp unsubscribe(pin, :rising, conn),
    do: Registry.unregister_match(InterruptRegistry, {__MODULE__, pin, :rising}, conn)

  defp unsubscribe(pin, :falling, conn),
    do: Registry.unregister_match(InterruptRegistry, {__MODULE__, pin, :falling}, conn)

  defp unsubscribe(pin, :both, conn) do
    Registry.unregister_match(InterruptRegistry, {__MODULE__, pin, :rising}, conn)
    Registry.unregister_match(InterruptRegistry, {__MODULE__, pin, :falling}, conn)
  end

  defp any_pin_subs?(pin) do
    rising_subs =
      InterruptRegistry
      |> Registry.lookup({__MODULE__, pin, :rising})

    falling_subs =
      InterruptRegistry
      |> Registry.lookup({__MODULE__, pin, :falling})

    rising_subs
    |> Stream.concat(falling_subs)
    |> Enum.any?()
  end
end
