defmodule WaferDriverElixirALE.GPIO.DispatcherTest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.ElixirALE.GPIO.Dispatcher, as: Dispatcher
  alias Wafer.Driver.ElixirALE.GPIO.Wrapper
  alias Wafer.InterruptRegistry, as: IR
  import Mimic
  @moduledoc false

  setup do
    Supervisor.terminate_child(Wafer.Supervisor, IR)
    Supervisor.restart_child(Wafer.Supervisor, IR)
    {:ok, []}
  end

  describe "handle_call/3" do
    test "enabling rising interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_int, 1, fn pid, pin_condition ->
        assert pid == conn.pid
        assert pin_condition == :rising
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :rising, :metadata, self()}, nil, state())

      assert IR.count_subscriptions({Dispatcher, 1}, :rising) == 1
    end

    test "enabling falling interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_int, 1, fn pid, pin_condition ->
        assert pid == conn.pid
        assert pin_condition == :falling
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :falling, :metadata, self()}, nil, state())

      assert IR.count_subscriptions({Dispatcher, 1}, :falling) == 1
    end

    test "enabling both interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_int, 1, fn pid, pin_condition ->
        assert pid == conn.pid
        assert pin_condition == :both
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :both, :metadata, self()}, nil, state())

      assert IR.count_subscriptions({Dispatcher, 1}, :both) == 1
    end

    test "disabling rising interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :rising, :metadata, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :rising)
    end

    test "disabling falling interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :falling, :metadata, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :falling)
    end

    test "disabling both interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :both, :metadata, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :both)
    end
  end

  describe "handle_info/2" do
    test "publishing rising interrupts" do
      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :rising}, state)

      assert_received {:interrupt, ^conn, :rising, :metadata}
    end

    test "publishing falling interrupts" do
      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call(
          {:enable, conn(), :both, :metadata, self()},
          nil,
          state()
        )

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :falling}, state)

      assert_received {:interrupt, ^conn, :falling, :metadata}
    end
  end

  defp conn(opts \\ []), do: Enum.into(opts, %{pin: pin(), pid: self()})
  defp state(opts \\ []), do: Enum.into(opts, %{})
  defp pin, do: 1
end
