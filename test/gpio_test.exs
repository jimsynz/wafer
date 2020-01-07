defmodule WaferGPIOTest do
  use ExUnit.Case, async: true
  alias Wafer.Driver.Circuits.GPIO, as: Driver
  alias Wafer.GPIO
  alias Wafer.GPIO.Wafer.Driver.Circuits.GPIO, as: Impl
  import Mimic
  Code.require_file("test/support/test_utils.exs")
  @moduledoc false

  setup do
    Mimic.copy(Impl)
    {:ok, []}
  end

  describe "__deriving___/3" do
    test "deriving with default key name" do
      mod = test_mod()
      assert GPIO.impl_for!(struct(mod, conn: :noop))
    end

    test "deriving with a specified key name" do
      mod = test_mod(:marty)
      assert GPIO.impl_for!(struct(mod, fruit: :noop))
    end

    test "read a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:read, 1, fn conn ->
        assert conn == %Driver{}
        {:ok, 0, conn}
      end)

      assert {:ok, 0, ^outer_struct} = GPIO.read(outer_struct)
    end

    test "write a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:write, 1, fn conn, value ->
        assert conn == %Driver{}
        assert value == 1
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = GPIO.write(outer_struct, 1)
    end

    test "direction on a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:direction, 1, fn conn, direction ->
        assert conn == %Driver{}
        assert direction == :out
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = GPIO.direction(outer_struct, :out)
    end

    test "enabling interrupt on a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:enable_interrupt, 1, fn conn, condition, _metadata ->
        assert conn == %Driver{}
        assert condition == :rising
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = GPIO.enable_interrupt(outer_struct, :rising, nil)
    end

    test "disabling interrupt on a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:disable_interrupt, 1, fn conn, condition ->
        assert conn == %Driver{}
        assert condition == :rising
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = GPIO.disable_interrupt(outer_struct, :rising)
    end

    test "setting pull mode on a derived pin" do
      outer_mod = test_mod()
      outer_struct = struct(outer_mod, conn: %Driver{})

      Impl
      |> expect(:pull_mode, 1, fn conn, condition ->
        assert conn == %Driver{}
        assert condition == :pull_up
        {:ok, conn}
      end)

      assert {:ok, ^outer_struct} = GPIO.pull_mode(outer_struct, :pull_up)
    end
  end

  defp test_mod(key \\ :conn) do
    mod = TestUtils.random_module_name()

    if key == :conn do
      defmodule mod do
        @derive GPIO
        defstruct [:conn]
      end
    else
      defmodule mod do
        @derive {GPIO, key: key}
        defstruct [key]
      end
    end

    mod
  end
end
