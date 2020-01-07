defmodule WaferCircuits.SPITest do
  use ExUnit.Case, async: true
  use Mimic
  alias Wafer.Driver.Circuits.SPI, as: Subject
  alias Wafer.Driver.Circuits.SPI.Wrapper
  alias Wafer.SPI
  @moduledoc false

  describe "acquire/1" do
    test "opens the bus" do
      Wrapper
      |> expect(:open, 1, fn bus, opts ->
        assert bus == "spidev0.0"
        assert opts == []
        {:ok, :erlang.make_ref()}
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

      Wrapper
      |> expect(:close, 1, fn ref ->
        assert ref == conn.ref
        :ok
      end)

      assert :ok = Subject.release(conn)
    end
  end

  describe "SPI.transfer/2" do
    test "transfers data to and from the bus" do
      conn = conn()

      Wrapper
      |> expect(:transfer, 1, fn ref, data ->
        assert ref == conn.ref
        assert data == <<0, 0>>
        {:ok, <<1, 1>>}
      end)

      assert {:ok, <<1, 1>>, %Subject{}} = SPI.transfer(conn, <<0, 0>>)
    end
  end

  defp conn, do: %Subject{ref: :erlang.make_ref(), bus: "spidev0.0"}
end
