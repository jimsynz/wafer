defmodule WaferElixirALEI2CTest do
  use ExUnit.Case, async: true
  use Mimic
  alias ElixirALE.I2C, as: Driver
  alias Wafer.Chip
  alias Wafer.Driver.ElixirALEI2C, as: Subject
  alias Wafer.I2C
  @moduledoc false

  describe "acquire/1" do
    test "opens the bus and verifies that the device is present" do
      buspid = self()
      busname = "i2c-1"
      address = 0x13

      Driver
      |> expect(:start_link, 1, fn bus, address ->
        assert bus == busname
        assert address == 0x13
        {:ok, buspid}
      end)
      |> expect(:detect_devices, 1, fn pid ->
        assert buspid == pid
        [address]
      end)

      assert {:ok, %Subject{} = conn} = Subject.acquire(bus_name: busname, address: address)
    end

    test "when the device is not present on the bus" do
      buspid = self()
      busname = "i2c-1"
      address = 0x13

      Driver
      |> expect(:start_link, 1, fn bus, address ->
        assert bus == busname
        assert address == 0x13
        {:ok, buspid}
      end)
      |> expect(:detect_devices, 1, fn pid ->
        assert buspid == pid
        []
      end)

      assert {:error, _reason} = Subject.acquire(bus_name: busname, address: address)
    end

    test "when the device is not present on the bus but an override is forced" do
      buspid = self()
      busname = "i2c-1"
      address = 0x13

      Driver
      |> expect(:start_link, 1, fn bus, address ->
        assert bus == busname
        assert address == 0x13
        {:ok, buspid}
      end)
      |> expect(:detect_devices, 1, fn pid ->
        assert buspid == pid
        []
      end)

      assert {:ok, %Subject{} = conn} =
               Subject.acquire(bus_name: busname, address: address, force: true)
    end
  end

  describe "release/1" do
    test "closes the bus connection" do
      conn = conn()

      Driver
      |> expect(:release, 1, fn pid ->
        assert pid == conn.pid
        :ok
      end)

      assert :ok = Subject.release(conn)
    end
  end

  describe "Chip.read_register/3" do
    test "reads from the device's register" do
      conn = conn()

      Driver
      |> expect(:write_read, 1, fn pid, data, bytes ->
        assert pid == conn.pid
        assert data == <<0>>
        assert bytes == 2
        <<0, 0>>
      end)

      assert {:ok, <<0, 0>>} = Chip.read_register(conn, 0, 2)
    end
  end

  describe "Chip.write_register/3" do
    test "writes to the device's register" do
      conn = conn()

      Driver
      |> expect(:write, 1, fn pid, data ->
        assert pid == conn.pid
        assert data == <<1, 2, 3>>
        :ok
      end)

      assert {:ok, %Subject{}} = Chip.write_register(conn, 1, <<2, 3>>)
    end
  end

  describe "Chip.swap_register/3" do
    test "swaps the device's register value for a new value, returning the old value" do
      conn = conn()

      Driver
      |> expect(:write_read, 1, fn pid, data, bytes ->
        assert pid == conn.pid
        assert data == <<0>>
        assert bytes == 2
        <<0, 0>>
      end)

      Driver
      |> expect(:write, 1, fn pid, data ->
        assert pid == conn.pid
        assert data == <<0, 1, 1>>
        :ok
      end)

      assert {:ok, <<0, 0>>, %Subject{}} = Chip.swap_register(conn, 0, <<1, 1>>)
    end
  end

  describe "I2C.read/2" do
    test "reads from the device" do
      conn = conn()

      Driver
      |> expect(:read, 1, fn pid, bytes ->
        assert pid == conn.pid
        assert bytes == 2
        <<0, 0>>
      end)

      assert {:ok, <<0, 0>>} = I2C.read(conn, 2)
    end
  end

  describe "I2C.write/2" do
    test "it writes to the device" do
      conn = conn()

      Driver
      |> expect(:write, 1, fn pid, data ->
        assert pid == conn.pid
        assert data == <<0, 0>>
        :ok
      end)

      assert {:ok, %Subject{}} = I2C.write(conn, <<0, 0>>)
    end
  end

  describe "I2C.write_read/3" do
    test "it writes to then reads from the device" do
      conn = conn()

      Driver
      |> expect(:write_read, 1, fn pid, data, bytes ->
        assert pid == conn.pid
        assert data == <<1>>
        assert bytes == 2

        <<0, 0>>
      end)

      assert {:ok, <<0, 0>>, %Subject{}} = I2C.write_read(conn, <<1>>, 2)
    end
  end

  describe "I2C.detect_devices/1" do
    test "it detects devices" do
      conn = conn()

      Driver
      |> expect(:detect_devices, 1, fn pid ->
        assert conn.pid == pid
        [conn.address]
      end)

      assert {:ok, [0x13]} = I2C.detect_devices(conn)
    end
  end

  defp conn, do: %Subject{pid: self(), bus: "i2c-1", address: 0x13}
end
