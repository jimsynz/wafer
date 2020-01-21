defmodule Wafer.Driver.ElixirALE.GPIO.Dispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.Driver.ElixirALE.GPIO.Wrapper
  alias Wafer.{Conn, GPIO, InterruptRegistry}

  @allowed_pin_conditions ~w[rising falling both]a

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `ElixirALE`.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: Dispatcher)

  @doc """
  Enable interrupts for this connection using the specified pin_condition.
  """
  @spec enable(Conn.t(), GPIO.pin_condition(), any) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(%{pin: pin} = conn, pin_condition, metadata \\ nil)
      when pin_condition in @allowed_pin_conditions do
    with {:ok, conn} <- GenServer.call(Dispatcher, {:enable, conn, pin_condition}),
         :ok <- InterruptRegistry.subscribe(key(pin), pin_condition, conn, metadata) do
      {:ok, conn}
    end
  end

  @doc """
  Disable interrupts for this connection on the specified pin_condition.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_condition) when pin_condition in @allowed_pin_conditions,
    do: GenServer.call(Dispatcher, {:disable, conn, pin_condition})

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:enable, %{pid: pid} = conn, pin_condition}, _from, state)
      when pin_condition in @allowed_pin_conditions do
    case Wrapper.set_int(pid, pin_condition) do
      :ok -> {:reply, {:ok, conn}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:disable, %{pin: pin} = conn, pin_condition}, _from, state)
      when pin_condition in @allowed_pin_conditions do
    :ok = InterruptRegistry.unsubscribe(key(pin), pin_condition, conn)
    {:reply, {:ok, conn}, state}
  end

  @impl true
  def handle_info({:gpio_interrupt, pin, condition}, state)
      when condition in @allowed_pin_conditions do
    {:ok, _} = InterruptRegistry.publish(key(pin), condition)
    {:noreply, state}
  end

  defp key(pin), do: {__MODULE__, pin}
end
