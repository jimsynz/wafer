defmodule WaferRegistersTest do
  use ExUnit.Case, async: true
  use Mimic
  alias Wafer.Chip

  describe "read-only register" do
    test "the register read function is defined" do
      assert function_exported?(test_mod(), :read_ro_test, 1)
    end

    test "the register write function is not defined" do
      refute function_exported?(test_mod(), :write_ro_test, 2)
    end

    test "the register swap function is not defined" do
      refute function_exported?(test_mod(), :swap_ro_test, 2)
    end

    test "the update register function is not defined" do
      refute function_exported?(test_mod(), :update_ro_test, 2)
    end

    test "the register can be read from" do
      mod = test_mod()

      Chip
      |> expect(:read_register, 1, fn conn, address, bytes ->
        {:read_register, conn, address, bytes}
      end)

      assert mod.read_ro_test(:conn) == {:read_register, :conn, 1, 3}
    end
  end

  describe "write-only register" do
    test "the register read function is not defined" do
      refute function_exported?(test_mod(), :read_wo_test, 1)
    end

    test "the register write function is defined" do
      assert function_exported?(test_mod(), :write_wo_test, 2)
    end

    test "the register swap function is not defined" do
      refute function_exported?(test_mod(), :swap_wo_test, 2)
    end

    test "the update register function is not defined" do
      refute function_exported?(test_mod(), :update_wo_test, 2)
    end

    test "the register can be written to" do
      mod = test_mod()

      Chip
      |> expect(:write_register, 1, fn conn, address, data ->
        {:write_register, conn, address, data}
      end)

      assert mod.write_wo_test(:conn, <<1, 1, 3, 4, 7>>) ==
               {:write_register, :conn, 2, <<1, 1, 3, 4, 7>>}
    end
  end

  describe "read-write register" do
    test "the register read function is not defined" do
      assert function_exported?(test_mod(), :read_rw_test, 1)
    end

    test "the register write function is defined" do
      assert function_exported?(test_mod(), :write_rw_test, 2)
    end

    test "the register swap function is  defined" do
      assert function_exported?(test_mod(), :swap_rw_test, 2)
    end

    test "the update register function is defined" do
      assert function_exported?(test_mod(), :update_rw_test, 2)
    end

    test "the register can be read from" do
      mod = test_mod()

      Chip
      |> expect(:read_register, 1, fn conn, address, bytes ->
        {:read_register, conn, address, bytes}
      end)

      assert mod.read_rw_test(:conn) == {:read_register, :conn, 3, 7}
    end

    test "the register can be written to" do
      mod = test_mod()

      Chip
      |> expect(:write_register, 1, fn conn, address, data ->
        {:write_register, conn, address, data}
      end)

      assert mod.write_rw_test(:conn, <<1, 1, 3, 4, 7, 11, 18>>) ==
               {:write_register, :conn, 3, <<1, 1, 3, 4, 7, 11, 18>>}
    end

    test "the register contents can be swapped" do
      mod = test_mod()

      Chip
      |> expect(:swap_register, 1, fn conn, address, data ->
        {:swap_register, conn, address, data}
      end)

      assert mod.swap_rw_test(:conn, <<1, 1, 3, 4, 7, 11, 18>>) ==
               {:swap_register, :conn, 3, <<1, 1, 3, 4, 7, 11, 18>>}
    end

    test "the register contents can be updated" do
      mod = test_mod()

      Chip
      |> expect(:read_register, 1, fn conn, address, bytes ->
        assert conn == :conn
        assert address == 3
        assert bytes == 7
        {:ok, <<1, 1, 3, 4, 7, 11, 18>>}
      end)
      |> expect(:write_register, 1, fn conn, address, data ->
        assert conn == :conn
        assert address == 3
        assert data == <<18, 11, 7, 4, 3, 1, 1>>
        :ok
      end)

      swapper = fn <<a, b, c, d, e, f, g>> -> <<g, f, e, d, c, b, a>> end

      assert mod.update_rw_test(:conn, swapper) == :ok
    end
  end

  defp test_mod do
    mod = TestUtils.random_module_name()

    defmodule mod do
      use Wafer.Registers

      defregister(:ro_test, 1, :ro, 3)
      defregister(:wo_test, 2, :wo, 5)
      defregister(:rw_test, 3, :rw, 7)
    end

    mod
  end
end
