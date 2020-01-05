defmodule WaferSPITest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.CircuitsSPI, as: Driver
  alias Wafer.SPI
  alias Wafer.SPI.Wafer.Driver.CircuitsSPI, as: Impl
  import Mimic
  Code.require_file("test/support/test_utils.exs")
  @moduledoc false

  setup do
    Mimic.copy(Impl)
    {:ok, []}
  end

  describe "__deriving__/3" do
    test "deriving with default key name" do
      mod = test_mod()
      assert SPI.impl_for!(struct(mod, conn: :noop))
    end

    test "deriving with a specified key name" do
      mod = test_mod(:marty)
      assert SPI.impl_for!(struct(mod, fruit: :noop))
    end

    test "transfer on a derived SPI device" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:transfer, 1, fn conn, data ->
        assert conn == %Driver{}
        assert data == <<0>>
        {:ok, <<1>>, conn}
      end)

      assert {:ok, <<1>>, ^outer_struct} = SPI.transfer(outer_struct, <<0>>)
    end
  end

  defp test_mod(key \\ :conn) do
    mod = TestUtils.random_module_name()

    if key == :conn do
      defmodule mod do
        @derive SPI
        defstruct [:conn]
      end
    else
      defmodule mod do
        @derive {SPI, key: key}
        defstruct [key]
      end
    end

    mod
  end
end
