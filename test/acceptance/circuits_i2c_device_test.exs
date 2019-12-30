defmodule WaferAcceptanceCircuitsI2CDeviceTest do
  use ExUnit.Case, async: true

  # Only run acceptance tests if the fake drivers are not loaded.
  if System.get_env("FAKE_DRIVERS") == "false" do
    alias Wafer.Driver.CircuitsI2C, as: Driver

    defmodule HTS221 do
      use Wafer.Registers

      @moduledoc """
      A not very useful driver for the HTS221 humidity sensor on the Pi Sense Hat.
      """

      defregister(:who_am_i, 0x0F, :ro, 1)
      defregister(:ctrl_reg1, 0x20, :rw, 1)

      def on?(conn) do
        case read_ctrl_reg1(conn) do
          {:ok, <<1::integer-size(1), _::bits>>} -> true
          _ -> false
        end
      end

      def turn_on(conn), do: write_ctrl_reg1(conn, <<1::integer-size(1), 0::integer-size(7)>>)
      def turn_off(conn), do: write_ctrl_reg1(conn, <<0>>)
    end

    describe "generated registers" do
      test "reading" do
        {:ok, conn} = Driver.acquire(bus_name: "i2c-1", address: 0x5F)

        assert {:ok, <<0xBC>>} = HTS221.read_who_am_i(conn)
      end

      test "reading and writing" do
        {:ok, conn} = Driver.acquire(bus_name: "i2c-1", address: 0x5F)

        assert {:ok, conn} = HTS221.turn_on(conn)
        assert HTS221.on?(conn) == true
        assert {:ok, conn} = HTS221.turn_off(conn)
        assert HTS221.on?(conn) == false
      end
    end
  end
end
