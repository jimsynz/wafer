defmodule WaferAcceptanceElixirALE.I2CDeviceTest do
  use ExUnit.Case, async: true

  # Only run acceptance tests if the fake drivers are not loaded.
  if System.get_env("SENSE_HAT_PRESENT") == "true" do
    alias Wafer.Driver.ElixirALE.I2C, as: Driver

    defmodule LPS25H do
      use Wafer.Registers

      @moduledoc """
      A not very useful driver for the LPS25H pressure senser on the Pi Sense Hat.
      """

      defregister(:who_am_i, 0x0F, :ro, 1)
      defregister(:ctrl_reg1, 0x20, :rw, 1)

      def on?(conn) do
        case read_ctrl_reg1(conn) do
          {:ok, <<1::integer-size(1), _::integer-size(7)>>} -> true
          _ -> false
        end
      end

      def turn_on(conn), do: write_ctrl_reg1(conn, <<1::integer-size(1), 0::integer-size(7)>>)
      def turn_off(conn), do: write_ctrl_reg1(conn, <<0>>)
    end

    describe "generated registers" do
      test "reading" do
        {:ok, conn} = Driver.acquire(bus_name: "i2c-1", address: 0x5C)

        assert {:ok, <<0xBD>>} = LPS25H.read_who_am_i(conn)
      end

      test "reading and writing" do
        {:ok, conn} = Driver.acquire(bus_name: "i2c-1", address: 0x5C)

        assert {:ok, conn} = LPS25H.turn_on(conn)
        assert LPS25H.on?(conn) == true
        assert {:ok, conn} = LPS25H.turn_off(conn)
        assert LPS25H.on?(conn) == false
      end
    end
  end
end
