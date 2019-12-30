defmodule TestUtils do
  @moduledoc false

  def random_module_name do
    name =
      16
      |> :crypto.strong_rand_bytes()
      |> Base.encode64(padding: false)

    Module.concat(__MODULE__, name)
  end
end
