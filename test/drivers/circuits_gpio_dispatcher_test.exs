defmodule WaferDriverCircuits.GPIO.DispatcherTest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.Circuits.GPIO.Dispatcher, as: Dispatcher
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.InterruptRegistry, as: IR
  import Mimic
  @moduledoc false

  setup do
    Supervisor.terminate_child(Wafer.Supervisor, IR)
    Supervisor.restart_child(Wafer.Supervisor, IR)
    stub(Wrapper, :identifiers, fn _spec -> :error end)
    {:ok, []}
  end

  describe "handle_call/3" do
    test "enabling rising interrupts" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :rising
        :ok
      end)

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :rising}, nil, state())
    end

    test "enabling falling interrupts" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :falling
        :ok
      end)

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :falling}, nil, state())
    end

    test "enabling both interrupts" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> expect(:set_interrupts, 1, fn ref, pin_condition ->
        assert ref == conn.ref
        assert pin_condition == :both
        :ok
      end)

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:enable, conn, :both}, nil, state())
    end

    test "enabling seeds the current pin value so the initial-value notification is filtered" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 1 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      assert state.values == %{conn.ref => 1}

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, conn.pin, :ts, 1}, state)

      refute_received {:interrupt, _conn, _condition, _metadata}
    end

    test "enabling learns spec aliases so backends that emit a normalised form are matched" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)
      |> stub(:identifiers, fn 1 ->
        {:ok, %{location: {"chip", 1}, controller: "chip", label: "PIO1"}}
      end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      assert Map.has_key?(state.ref_by_spec, 1)
      assert Map.has_key?(state.ref_by_spec, {"chip", 1})
      assert Map.has_key?(state.ref_by_spec, {"chip", "PIO1"})
      assert Map.has_key?(state.ref_by_spec, "PIO1")
      assert state.pin_by_ref == %{conn.ref => 1}
    end

    test "disabling rising interrupts" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :rising}, nil, state())

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :rising}, nil, state())
    end

    test "disabling falling interrupts" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      Dispatcher.handle_call({:enable, conn, :falling}, nil, state())

      assert {:reply, {:ok, _conn}, _state} =
               Dispatcher.handle_call({:disable, conn, :falling}, nil, state())
    end

    test "disabling both interrupts clears state.values and aliases once no subscribers remain" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      assert {:reply, {:ok, _conn}, state} =
               Dispatcher.handle_call({:disable, conn, :both}, nil, state)

      refute Map.has_key?(state.values, conn.ref)
      refute Map.has_key?(state.pin_by_ref, conn.ref)
      refute Map.has_key?(state.ref_by_spec, conn.pin)
    end

    test "arms the hardware with the union of active edges on the same ref" do
      conn = conn()
      test_pid = self()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _ref, trigger ->
        send(test_pid, {:set_interrupts, trigger})
        :ok
      end)

      {:reply, {:ok, _}, state} =
        Dispatcher.handle_call({:enable, conn, :rising}, nil, state())

      assert_received {:set_interrupts, :rising}

      {:reply, {:ok, _}, state} =
        Dispatcher.handle_call({:enable, conn, :falling}, nil, state)

      assert_received {:set_interrupts, :both}

      {:reply, {:ok, _}, state} =
        Dispatcher.handle_call({:disable, conn, :rising}, nil, state)

      assert_received {:set_interrupts, :falling}

      {:reply, {:ok, _}, _state} =
        Dispatcher.handle_call({:disable, conn, :falling}, nil, state)

      assert_received {:set_interrupts, :none}
    end
  end

  describe "enable/3" do
    test "registers the subscriber before arming the hardware" do
      conn = conn()
      test_pid = self()
      key = {Dispatcher, conn.pin}

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _ref, _trigger ->
        send(test_pid, {:subscribed?, IR.subscribers?(key, :rising)})
        :ok
      end)
      |> Mimic.allow(self(), Process.whereis(Dispatcher))

      {:ok, _conn} = Dispatcher.enable(conn, :rising)

      assert_received {:subscribed?, true}
    end

    test "rolls back the subscription if arming the hardware fails" do
      conn = conn()
      key = {Dispatcher, conn.pin}

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _ref, _trigger -> {:error, :boom} end)
      |> Mimic.allow(self(), Process.whereis(Dispatcher))

      assert {:error, :boom} = Dispatcher.enable(conn, :rising)
      refute IR.subscribers?(key, :rising)
    end
  end

  describe "disable/2" do
    test "unsubscribes the calling process from the interrupt registry" do
      conn = conn()
      key = {Dispatcher, conn.pin}

      Wrapper
      |> stub(:set_interrupts, fn _, _ -> :ok end)
      |> Mimic.allow(self(), Process.whereis(Dispatcher))

      :ok = IR.subscribe(key, :rising, conn)
      assert IR.subscribers?(key, :rising)

      {:ok, _conn} = Dispatcher.disable(conn, :rising)

      refute IR.subscribers?(key, :rising)
    end
  end

  describe "handle_info/2" do
    test "publishing interrupts when the value rises" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      IR
      |> expect(:publish, 1, fn _key, condition ->
        assert condition == :rising
      end)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, conn.pin, :ts, 1}, state)
    end

    test "publishing interrupts when the value falls" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 1 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      IR
      |> expect(:publish, 1, fn _key, condition ->
        assert condition == :falling
      end)

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, conn.pin, :ts, 0}, state)
    end

    test "ignoring interrupts when the value stays high" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 1 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, conn.pin, :ts, 1}, state)

      refute_received {:interrupt, _conn, _condition, _metadata}
    end

    test "ignoring interrupts when the value stays low" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      {:noreply, _state} = Dispatcher.handle_info({:circuits_gpio, conn.pin, :ts, 0}, state)

      refute_received {:interrupt, _conn, _condition, _metadata}
    end

    test "matches an interrupt arriving under a backend-normalised tuple spec" do
      conn = conn()

      Wrapper
      |> stub(:read, fn _ref -> 0 end)
      |> stub(:set_interrupts, fn _, _ -> :ok end)
      |> stub(:identifiers, fn 1 ->
        {:ok, %{location: {"chip", 1}, controller: "chip", label: "PIO1"}}
      end)

      {:reply, {:ok, _conn}, state} =
        Dispatcher.handle_call({:enable, conn, :both}, nil, state())

      IR
      |> expect(:publish, 1, fn key, condition ->
        assert key == {Dispatcher, conn.pin}
        assert condition == :rising
      end)

      {:noreply, _state} =
        Dispatcher.handle_info({:circuits_gpio, {"chip", "PIO1"}, :ts, 1}, state)
    end

    test "silently ignores interrupts for unknown gpio_specs" do
      state = state()

      assert {:noreply, ^state} =
               Dispatcher.handle_info({:circuits_gpio, {"unknown", "x"}, :ts, 1}, state)

      refute_received {:interrupt, _, _, _}
    end

    test "ignores unrelated info messages" do
      state = state()
      assert {:noreply, ^state} = Dispatcher.handle_info(:whatever, state)
    end
  end

  defp conn(opts \\ []),
    do:
      Enum.into(opts, %{
        pin: pin(),
        ref: %{__struct__: Circuits.GPIO.CDev, ref: :erlang.make_ref()}
      })

  defp state(opts \\ []),
    do:
      Enum.into(opts, %{
        values: %{},
        triggers: %{},
        ref_by_spec: %{},
        pin_by_ref: %{}
      })

  defp pin, do: 1
end
