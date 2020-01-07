defmodule WaferDriverCircuits.GPIO.DispatcherTest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.Circuits.GPIO.Dispatcher, as: Dispatcher
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.InterruptRegistry, as: IR
  import Mimic
  @moduledoc false

  describe "handle_call/3" do
    test "enabling rising interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :rising
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :rising, :metadata, self()}, nil, state())

      assert IR.subscribers?({Dispatcher, 1}, :rising)
    end

    test "enabling falling interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :falling
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :falling, :metadata, self()}, nil, state())

      assert IR.subscribers?({Dispatcher, 1}, :falling)
    end

    test "enabling both interrupts" do
      conn = conn()

      Wrapper
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :both
        :ok
      end)

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :both, :metadata, self()}, nil, state())

      assert IR.subscribers?({Dispatcher, 1}, :both)
    end

    test "disabling rising interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :rising, :metadata, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :rising)
    end

    test "disabling falling interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :falling, :metadta, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :falling)
    end

    test "disabling both interrupts" do
      conn = conn()

      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :both, :metadata, self()}, nil, state())

      assert {:reply, {:ok, conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state())

      refute IR.subscribers?({Dispatcher, 1}, :both)
    end
  end

  describe "handle_info/2" do
    test "publishing interrupts when the value was previously unknown" do
      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      assert_received {:interrupt, ^conn, :rising, :metadata}
    end

    test "publishing interrupts when the value rises" do
      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      state = state(values: %{1 => 0})

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      assert_received {:interrupt, ^conn, :rising, :metadata}
    end

    test "publishing interrupts when the value falls" do
      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      state = state(values: %{1 => 1})

      {:reply, {:ok, conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 0}, state)

      assert_received {:interrupt, ^conn, :falling, :metadata}
    end

    test "ignoring interrupts when the value stays high" do
      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      state = state(values: %{1 => 1})

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 1}, state)

      refute_received {:interrupt, _conn, _condition, _metadata}
    end

    test "ignoring interrupts when the value stays low" do
      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      state = state(values: %{1 => 0})

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn(), :both, :metadata, self()}, nil, state)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, 1, :ts, 0}, state)

      refute_received {:interrupt, _conn, _condition, _metadata}
    end
  end

  defp conn(opts \\ []), do: Enum.into(opts, %{pin: pin(), ref: :erlang.make_ref()})
  defp state(opts \\ []), do: Enum.into(opts, %{values: %{}})
  defp pin, do: 1
end
