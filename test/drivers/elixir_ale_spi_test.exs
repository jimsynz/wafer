defmodule WaferElixirALESPITest do
  use ExUnit.Case, async: true
  use Mimic
  alias ElixirALE.SPI, as: Driver
  alias Wafer.Driver.ElixirALESPI, as: Subject
  alias Wafer.SPI
  @moduledoc false

  describe "acquire/1" do
    test "opens the bus" do
      Driver
      |> expect(:start_link, 1, fn bus, spi_opts, opts ->
        assert bus == "spidev0.0"
        assert spi_opts == []
        assert opts == []
        {:ok, self()}
      end)

      assert {:ok, %Subject{}} = Subject.acquire(bus_name: "spidev0.0")
    end

    test "when the bus name is not specified it returns an error" do
      assert {:error, _} = Subject.acquire([])
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

  describe "SPI.transfer/2" do
    test "transfers data to and from the bus" do
      conn = conn()

      Driver
      |> expect(:transfer, 1, fn pid, data ->
        assert pid == conn.pid
        assert data == <<0, 0>>
        <<1, 1>>
      end)

      assert {:ok, <<1, 1>>, %Subject{}} = SPI.transfer(conn, <<0, 0>>)
    end
  end

  defp conn, do: %Subject{pid: self(), bus: "spidev0.0"}
end
