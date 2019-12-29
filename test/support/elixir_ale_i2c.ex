defmodule ElixirALE.I2C do
  def write_read(pid, data, bytes)
      when is_pid(pid) and is_bitstring(data) and is_integer(bytes) and bytes >= 1 do
    bits = bytes * 8
    <<0::unsigned-integer-size(bits)>>
  end

  def write(pid, data) when is_pid(pid) and is_bitstring(data), do: :ok
end
