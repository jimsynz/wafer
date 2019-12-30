defmodule WaferDriverElixirALEGPIODispatcherTest do
  use ExUnit.Case, async: true
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.Driver.ElixirALEGPIODispatcher, as: Dispatcher
  alias Wafer.InterruptRegistry
  import Mimic
  @moduledoc false

  describe "handle_call/3" do
    test "enabling rising interrupts" do
      conn = conn()

      Driver
      |> expect(:set_int, 1, fn pid, trigger ->
        assert pid == conn.pid
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
      |> expect(:set_int, 1, fn pid, trigger ->
        assert pid == conn.pid
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
      |> expect(:set_int, 1, fn pid, trigger ->
        assert pid == conn.pid
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

      Driver
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :rising, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == []
    end

    test "disabling falling interrupts" do
      conn = conn()

      Driver
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :falling, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == []
    end

    test "disabling both interrupts" do
      conn = conn()

      Driver
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :both, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state())

      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :rising}, conn) == []
      assert Registry.match(InterruptRegistry, {Dispatcher, 1, :falling}, conn) == []
    end
  end

  describe "handle_info/2" do
    test "publishing rising interrupts" do
      Driver
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :rising}, state)

      assert_received {:interrupt, ^conn, :rising}
    end

    test "publishing falling interrupts" do
      Driver
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, self()}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :falling}, state)

      assert_received {:interrupt, ^conn, :falling}
    end
  end

  defp conn(opts \\ []), do: Enum.into(opts, %{pin: pin(), pid: self()})
  defp state(opts \\ []), do: Enum.into(opts, %{})
  defp pin, do: 1
end
