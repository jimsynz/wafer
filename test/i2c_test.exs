defmodule WaferI2CTest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.Circuits.I2C, as: Driver
  alias Wafer.I2C
  alias Wafer.I2C.Wafer.Driver.Circuits.I2C, as: Impl
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
      assert I2C.impl_for!(struct(mod, conn: :noop))
    end

    test "deriving with a specified key name" do
      mod = test_mod(:marty)
      assert I2C.impl_for!(struct(mod, fruit: :noop))
    end

    test "reading a derived I2C device" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:read, 1, fn conn, bytes, opts ->
        assert conn == %Driver{}
        assert bytes == 2
        assert opts == []
        {:ok, <<0>>}
      end)

      assert {:ok, <<0>>} = I2C.read(outer_struct, 2, [])
    end

    test "writing a derived I2C device" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:write, 1, fn conn, data, opts ->
        assert conn == %Driver{}
        assert data == <<0>>
        assert opts == []
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = I2C.write(outer_struct, <<0>>, [])
    end

    test "write_read on a derived I2C device" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:write_read, 1, fn conn, data, bytes, opts ->
        assert conn == %Driver{}
        assert data == <<0>>
        assert bytes == 1
        assert opts == []
        {:ok, <<1>>, conn}
      end)

      assert {:ok, <<1>>, ^outer_struct} = I2C.write_read(outer_struct, <<0>>, 1, [])
    end

    test "detect_devices on a derived I2C device" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:detect_devices, 1, fn conn ->
        assert conn == %Driver{}
        {:ok, []}
      end)

      assert {:ok, []} = I2C.detect_devices(outer_struct)
    end
  end

  defp test_mod(key \\ :conn) do
    mod = TestUtils.random_module_name()

    if key == :conn do
      defmodule mod do
        @derive I2C
        defstruct [:conn]
      end
    else
      defmodule mod do
        @derive {I2C, key: key}
        defstruct [key]
      end
    end

    mod
  end
end
