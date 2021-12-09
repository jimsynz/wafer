defmodule TestUtils do
  @moduledoc false

  @chars ~w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]

  def random_module_name do
    name = random_string("", 16)

    Module.concat(__MODULE__, name)
  end

  defp random_string(str, 0), do: str

  defp random_string(str, count) do
    "#{str}#{Enum.random(@chars)}"
    |> random_string(count - 1)
  end
end
