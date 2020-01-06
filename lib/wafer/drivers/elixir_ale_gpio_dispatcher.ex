defmodule Wafer.Driver.ElixirALEGPIODispatcher do
  use GenServer
  alias __MODULE__
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.{Conn, GPIO, InterruptRegistry}

  @allowed_pin_conditions ~w[rising falling both]a

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `ElixirALE`.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: ElixirALEGPIODispatcher)

  @doc """
  Enable interrupts for this connection using the specified pin_condition.
  """
  @spec enable(Conn.t(), GPIO.pin_condition(), any) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(conn, pin_condition, metadata) when pin_condition in @allowed_pin_conditions,
    do: GenServer.call(ElixirALEGPIODispatcher, {:enable, conn, pin_condition, metadata, self()})

  @doc """
  Disable interrupts for this connection on the specified pin_condition.
  """
  @spec disable(Conn.t(), GPIO.pin_condition()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_condition) when pin_condition in @allowed_pin_conditions,
    do: GenServer.call(ElixirALEGPIODispatcher, {:disable, conn, pin_condition})

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(
        {:enable, %{pin: pin, pid: pid} = conn, pin_condition, metadata, receiver},
        _from,
        state
      )
      when pin_condition in @allowed_pin_conditions do
    with :ok <- Driver.set_int(pid, pin_condition),
         :ok <- InterruptRegistry.subscribe(key(pin), pin_condition, conn, metadata, receiver) do
      {:reply, {:ok, conn}, state}
    else
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
