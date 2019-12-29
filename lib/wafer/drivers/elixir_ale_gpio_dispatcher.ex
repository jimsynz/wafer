defmodule Wafer.Driver.ElixirAleGPIODispatcher do
  use GenServer
  alias __MODULE__
  alias Wafer.{Conn, GPIO, InterruptRegistry}
  alias ElixirALE.GPIO, as: Driver

  @allowed_triggers ~w[rising falling both]a

  @moduledoc """
  This module implements a simple dispatcher for GPIO interrupts when using
  `ElixirALE`.
  """

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [opts], name: ElixirAleGPIODispatcher)

  @doc """
  Enable intterrupts for this connection using the specified trigger.
  """
  @spec enable(Conn.t(), GPIO.pin_trigger()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable(conn, pin_trigger) when pin_trigger in @allowed_triggers,
    do: GenServer.call(ElixirAleGPIODispatcher, {:enable, conn, pin_trigger})

  @doc """
  Disable interrupts for this connection on the specified trigger.
  """
  @spec disable(Conn.t(), GPIO.pin_trigger()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable(conn, pin_trigger) when pin_trigger in @allowed_triggers,
    do: GenServer.call(ElixirAleGPIODispatcher, {:disable, conn, pin_trigger})

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:enable, %{pin: pin, pid: pid} = conn, pin_trigger}, _from, state)
      when pin_trigger in @allowed_triggers do
    case Driver.set_int(pid, pin_trigger) do
      :ok ->
        subscription = {conn, pin_trigger}

        state =
          state
          |> Map.update(pin, MapSet.new([subscription]), &MapSet.put(&1, subscription))

        {:reply, {:ok, conn}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:disable, %{pin: pin} = conn, pin_trigger}, _from, state)
      when pin_trigger in @allowed_triggers do
    subscription = {conn, pin_trigger}

    pin_subscriptions =
      state
      |> Map.get(pin, MapSet.new())
      |> MapSet.delete(subscription)

    state =
      state
      |> Map.put(pin, pin_subscriptions)

    {:reply, {:ok, conn}, state}
  end

  @impl true
  def handle_info({:gpio_interrupt, pin, pin_trigger}, state)
      when pin_trigger in @allowed_triggers do
    state
    |> Map.get(pin, MapSet.new())
    |> Stream.filter(fn
      {_conn, ^pin_trigger} -> true
      {_conn, :both} -> true
      _ -> false
    end)
    |> Enum.each(fn {conn, _} = registry_key ->
      Registry.dispatch(InterruptRegistry, registry_key, fn pids ->
        for {pid, _} <- pids do
          send(pid, {:interrupt, conn, pin_trigger})
        end
      end)
    end)

    {:noreply, state}
  end
end
