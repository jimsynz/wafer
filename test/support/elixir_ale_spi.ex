defmodule ElixirALE.SPI do
  @moduledoc false
  def start_link(name, spi_opts \\ [], opts \\ [])
      when is_binary(name) and is_list(spi_opts) and is_list(opts),
      do: {:ok, self()}

  def release(pid) when is_pid(pid), do: :ok

  def transfer(pid, data) when is_pid(pid) and is_binary(data) do
    bits = bit_size(data)
    <<0::unsigned-integer-size(bits)>>
  end
end
