defmodule WaferDriverCircuitsGPIODispatcherTest do
  use ExUnit.Case, async: true
  alias Circuits.GPIO, as: Driver
  alias Wafer.Driver.CircuitsGPIODispatcher, as: Dispatcher
  alias Wafer.InterruptRegistry
  import Mimic
  @moduledoc false

  describe "handle_call/3" do
    test "enabling rising interrupts" do
      conn = conn()

      Driver
      |> expect(:set_interrupts, 1, fn ref, trigger ->
        assert ref == conn.ref
        assert trigger == :rising
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :rising, self()}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == [{self(), conn}]
    end

    test "enabling falling interrupts" do
      conn = conn()

      Driver
      |> expect(:set_interrupts, 1, fn ref, trigger ->
        assert ref == conn.ref
        assert trigger == :falling
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :falling, self()}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == [
               {self(), conn}
             ]
    end

    test "enabling both interrupts" do
      conn = conn()

      Driver
      |> expect(:set_interrupts, 1, fn ref, trigger ->
        assert ref == conn.ref
        assert trigger == :both
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :both, self()}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == [
               {self(), conn}
             ]

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == [
               {self(), conn}
             ]
    end

    test "disabling rising interrupts" do
      conn = conn()
      Dispatcher.handle_call({:enable, conn, :rising, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == []
    end

    test "disabling falling interrupts" do
      conn = conn()
      Dispatcher.handle_call({:enable, conn, :falling, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == []
    end

    test "disabling both interrupts" do
      conn = conn()
      Dispatcher.handle_call({:enable, conn, :both, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == []
      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == []
    end
  end

  describe "handle_info/2" do
    test "publishing interrupts when the value was previously unknown" do
      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      assert_received {:interrupt, ^conn, :rising}
    end

    test "publishing interrupts when the value rises" do
      state = state(values: %{1 => 0})

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      assert_received {:interrupt, ^conn, :rising}
    end

    test "publishing interrupts when the value falls" do
      state = state(values: %{1 => 1})

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 0}, state)

      assert_received {:interrupt, ^conn, :falling}
    end

    test "ignoring interrupts when the value stays high" do
      state = state(values: %{1 => 1})

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      refute_received {:interrupt, _conn, _condition}
    end

    test "ignoring interrupts when the value stays low" do
      state = state(values: %{1 => 0})

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 0}, state)

      refute_received {:interrupt, _conn, _condition}
    end
  end

  defp conn(opts \\ []), do: Enum.into(opts, %{pin: pin(), ref: :erlang.make_ref()})
  defp state(opts \\ []), do: Enum.into(opts, %{values: %{}})
  defp pin, do: 1
end
