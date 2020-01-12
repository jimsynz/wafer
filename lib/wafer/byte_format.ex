defmodule Wafer.ByteFormat do
  def i2b(i) when is_integer(i), do: i2b(<<i>>)
end
