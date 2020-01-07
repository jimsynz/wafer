defmodule WaferDriverElixirALE.GPIOTest do
  use ExUnit.Case, async: true
  use Mimic
  alias Wafer.Driver.ElixirALE.GPIO, as: Subject
  alias Wafer.Driver.ElixirALE.GPIO.Dispatcher, as: Dispatcher
  alias Wafer.Driver.ElixirALE.GPIO.Wrapper
  alias Wafer.GPIO, as: GPIO
  @moduledoc false

  describe "acquire/1" do
    test "opens the pin and creates the conn" do
      Wrapper
      |> expect(:start_link, 1, fn pin, direction, opts ->
        assert pin == 1
        assert direction == :out
        assert opts == []
        {:ok, self()}
      end)

      assert {:ok, %Subject{}} = Subject.acquire(pin: 1, direction: :out)
    end

    test "returns an error when the pin is not specified" do
      assert {:error, _} = Subject.acquire([])
    end
  end

  describe "release/1" do
    test "closes the pin" do
      conn = conn()

      Wrapper
      |> expect(:release, 1, fn pid ->
        assert pid == conn.pid
        :ok
      end)

      assert :ok = Subject.release(conn)
    end
  end

  describe "GPIO.read/1" do
    test "can read the pin value" do
      conn = conn()

      Wrapper
      |> expect(:read, 1, fn pid ->
        assert pid == conn.pid
        0
      end)

      assert {:ok, 0} = GPIO.read(conn)
    end
  end

  describe "GPIO.write/2" do
    test "can set the pin value" do
      conn = conn()

      Wrapper
      |> expect(:write, 1, fn pid, value ->
        assert pid == conn.pid
        assert value == 1
        :ok
      end)

      assert {:ok, %Subject{}} = GPIO.write(conn, 1)
    end
  end

  describe "GPIO.direction/2" do
    test "is not supported" do
      assert {:error, :not_supported} = GPIO.direction(conn(), :in)
    end
  end

  describe "GPIO.enable_interrupt/2" do
    test "subscribes the conn to interrupts" do
      conn = conn()

      Dispatcher
      |> expect(:enable, 1, fn conn1, pin_condition, _metadata ->
        assert conn1 == conn
        assert pin_condition == :rising
        :ok
      end)

      assert :ok = GPIO.enable_interrupt(conn, :rising)
    end
  end

  describe "GPIO.disable_interrupt/2" do
    test "unsubscribes the conn from interrupts" do
      conn = conn()

      Dispatcher
      |> expect(:disable, 1, fn conn1, pin_condition ->
        assert conn1 == conn
        assert pin_condition == :rising
        :ok
      end)

      assert :ok = GPIO.disable_interrupt(conn, :rising)
    end
  end

  describe "GPIO.pull_mode/2" do
    test "is not supported" do
      assert {:error, :not_supported} = GPIO.pull_mode(conn(), :pull_up)
    end
  end

  defp conn(opts \\ []), do: struct(%Subject{pin: pin(), pid: self()}, opts)
  defp pin, do: 1
end
