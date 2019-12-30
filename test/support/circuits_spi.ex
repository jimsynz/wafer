defmodule Circuits.SPI do
  @moduledoc false
  def open(name, opts \\ [])
      when is_binary(name) and is_list(opts),
      do: {:ok, self()}

  def close(ref) when is_reference(ref), do: :ok

  def transfer(ref, data) when is_reference(ref) and is_binary(data) do
    bits = bit_size(data)
    {:ok, <<0::unsigned-integer-size(bits)>>}
  end
end
