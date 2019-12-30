defmodule Wafer.Driver.ElixirALEGPIODispatcher do
  use GenServer
  alias __MODULE__
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.{Conn, GPIO, InterruptRegistry}

  @allowed_triggers ~w[rising falling both]a

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `ElixirALE`.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: ElixirALEGPIODispatcher)

  @doc """
  Enable intterrupts for this connection using the specified trigger.
  """
  @spec enable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(conn, pin_condition) when pin_condition in @allowed_triggers,
    do: GenServer.call(ElixirALEGPIODispatcher, {:enable, conn, pin_condition, self()})

  @doc """
  Disable interrupts for this connection on the specified trigger.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_condition) when pin_condition in @allowed_triggers,
    do: GenServer.call(ElixirALEGPIODispatcher, {:disable, conn, pin_condition})

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:enable, %{pin: pin, pid: pid} = conn, pin_condition, receiver}, _from, state)
      when pin_condition in @allowed_triggers do
    case Driver.set_int(pid, pin_condition) do
      :ok ->
        subscribe(pin, pin_condition, conn, receiver)
        {:reply, {:ok, conn}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:disable, %{pin: pin} = conn, pin_condition}, _from, state)
      when pin_condition in @allowed_triggers do
    unsubscribe(pin, pin_condition, conn)
    {:reply, {:ok, conn}, state}
  end

  @impl true
  def handle_info({:gpio_interrupt, pin, condition}, state)
      when condition in @allowed_triggers do
    Registry.dispatch(InterruptRegistry, {__MODULE__, pin, condition}, fn subs ->
      for {pid, conn} <- subs do
        send(pid, {:interrupt, conn, condition})
      end
    end)

    {:noreply, state}
  end

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
end
