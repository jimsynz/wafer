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

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :rising}, nil, state())
    end

    test "enabling falling interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_int, 1, fn pid, pin_condition ->
        assert pid == conn.pid
        assert pin_condition == :falling
        :ok
      end)

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :falling}, nil, state())
    end

    test "enabling both interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_int, 1, fn pid, pin_condition ->
        assert pid == conn.pid
        assert pin_condition == :both
        :ok
      end)

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :both}, nil, state())
    end

    test "disabling rising interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :rising}, nil, state())

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())
    end

    test "disabling falling interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :falling}, nil, state())

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())
    end

    test "disabling both interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state())
    end
  end

  describe "handle_info/2" do
    test "publishing rising interrupts" do
      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both}, nil, state())

      IR
      |> expect(:publish, 1, fn _key, condition ->
        assert condition == :rising
        {:ok, []}
      end)

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :rising}, state)
    end

    test "publishing falling interrupts" do
      Wrapper
      |> stub(:set_int, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call(
          {:enable, conn(), :both},
          nil,
          state()
        )

      IR
      |> expect(:publish, 1, fn _key, condition ->
        assert condition == :falling
        {:ok, []}
      end)

      {:noreply, _state} = Dispatcher.handle_info({:gpio_interrupt, 1, :falling}, state)
    end
  end

  defp conn(opts \\ []), do: Enum.into(opts, %{pin: pin(), pid: self()})
  defp state(opts \\ []), do: Enum.into(opts, %{})
  defp pin, do: 1
end
