defmodule WaferDriverCircuitsGPIOTest do
  use ExUnit.Case, async: true
  use Mimic
  alias Circuits.GPIO, as: Driver
  alias Wafer.Driver.CircuitsGPIO, as: Subject
  alias Wafer.Driver.CircuitsGPIODispatcher, as: Dispatcher
  alias Wafer.GPIO, as: GPIO
  @moduledoc false

  describe "acquire/1" do
    test "opens the pin and creates the conn" do
      Driver
      |> expect(:open, 1, fn pin, direction, opts ->
        assert pin == 1
        assert direction == :output
        assert opts == []
        {:ok, :erlang.make_ref()}
      end)

      assert {:ok, %Subject{}} = Subject.acquire(pin: 1, direction: :out)
    end
  end

  describe "release/1" do
    test "closes the pin" do
      conn = conn()

      Driver
      |> expect(:close, 1, fn ref ->
        assert ref == conn.ref
        :ok
      end)

      assert :ok = Subject.release(conn)
    end
  end

  describe "GPIO.read/1" do
    test "can read the pin value" do
      conn = conn()

      Driver
      |> expect(:read, 1, fn ref ->
        assert ref == conn.ref
        0
      end)

      assert {:ok, 0} = GPIO.read(conn)
    end
  end

  describe "GPIO.write/2" do
    test "can set the pin value" do
      conn = conn()

      Driver
      |> expect(:write, 1, fn ref, value ->
        assert ref == conn.ref
        assert value == 1
        :ok
      end)

      assert {:ok, %Subject{}} = GPIO.write(conn, 1)
    end
  end

  describe "GPIO.direction/2" do
    test "when the direction isn't changing" do
      Driver
      |> reject(:set_direction, 2)

      assert {:ok, %Subject{} = conn} = Subject.acquire(pin: 1, direction: :out)
      assert {:ok, %Subject{}} = GPIO.direction(conn, :out)
    end

    test "when the direction is changing" do
      assert {:ok, %Subject{} = conn} = Subject.acquire(pin: 1, direction: :out)

      Driver
      |> expect(:set_direction, 1, fn ref, direction ->
        assert ref == conn.ref
        assert direction == :in
        :ok
      end)

      assert {:ok, %Subject{}} = GPIO.direction(conn, :in)
    end
  end

  describe "GPIO.enable_interrupt/2" do
    test "subscribes the conn to interrupts" do
      conn = conn()

      Dispatcher
      |> expect(:enable, 1, fn conn1, trigger ->
        assert conn1 == conn
        assert trigger == :rising
        :ok
      end)

      assert :ok = GPIO.enable_interrupt(conn, :rising)
    end
  end

  describe "GPIO.disable_interrupt/2" do
    test "unsubscribes the conn from interrupts" do
      conn = conn()

      Dispatcher
      |> expect(:disable, 1, fn conn1, trigger ->
        assert conn1 == conn
        assert trigger == :rising
        :ok
      end)

      assert :ok = GPIO.disable_interrupt(conn, :rising)
    end
  end

  describe "GPIO.pull_mode/2" do
    test "sets the specified pull mode on the connection" do
      conn = conn()

      Driver
      |> expect(:set_pull_mode, 1, fn ref, mode ->
        assert ref == conn.ref
        assert mode == :pull_up
        :ok
      end)

      assert {:ok, %Subject{}} = GPIO.pull_mode(conn, :pull_up)
    end
  end

  defp conn(opts \\ []), do: struct(%Subject{pin: pin(), ref: :erlang.make_ref()}, opts)

  defp pin, do: 1
end
