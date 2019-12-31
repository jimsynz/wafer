defmodule WaferChipTest do
  use ExUnit.Case, async: true
  alias Wafer.Chip

  describe "__deriving__/3" do
    test "deriving with default key name" do
      mod = test_mod()
      assert Chip.impl_for!(struct(mod, conn: :noop))
    end

    test "deriving with a specified key name" do
      mod = test_mod(:marty)
      assert Chip.impl_for!(struct(mod, fruit: :noop))
    end
  end

  defp test_mod(key \\ :conn) do
    mod = random_module_name()

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

  defp random_module_name do
    name =
      16
      |> :crypto.strong_rand_bytes()
      |> Base.encode64(padding: false)

    Module.concat(__MODULE__, name)
  end
end
