defmodule WaferChipTest do
  use ExUnit.Case, async: true
  alias Wafer.Chip
  alias Wafer.Chip.Wafer.Driver.Circuits.I2C, as: Impl
  alias Wafer.Driver.Circuits.I2C, as: Driver
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
      assert Chip.impl_for!(struct(mod, conn: :noop))
    end

    test "deriving with a specified key name" do
      mod = test_mod(:marty)
      assert Chip.impl_for!(struct(mod, fruit: :noop))
    end

    test "reading a derived register" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:read_register, 1, fn conn, reg_addr, bytes ->
        assert conn == %Driver{}
        assert reg_addr == 2
        assert bytes == 1
        {:ok, <<0>>}
      end)

      Chip.read_register(outer_struct, 2, 1)
    end

    test "writing a derived register" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:write_register, 1, fn conn, reg_addr, data ->
        assert conn == %Driver{}
        assert reg_addr == 2
        assert data == <<0>>
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = Chip.write_register(outer_struct, 2, <<0>>)
    end

    test "swapping a derived register" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:swap_register, 1, fn conn, reg_addr, data ->
        assert conn == %Driver{}
        assert reg_addr == 2
        assert data == <<0>>
        {:ok, <<1>>, conn}
      end)

      assert {:ok, <<1>>, ^outer_struct} = Chip.swap_register(outer_struct, 2, <<0>>)
    end
  end

  defp test_mod(key \\ :conn) do
    mod = TestUtils.random_module_name()

    if key == :conn do
      defmodule mod do
        @derive Chip
        defstruct [:conn]
      end
    else
      defmodule mod do
        @derive {Chip, key: key}
        defstruct [key]
      end
    end

    mod
  end
end
