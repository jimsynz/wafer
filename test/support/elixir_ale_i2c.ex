defmodule ElixirALE.I2C do
  import Wafer.Guards
  @moduledoc false

  def read(pid, bytes, options \\ [])
      when is_pid(pid) and is_byte_size(bytes) and is_list(options) do
    bits = bytes * 8
    <<0::unsigned-integer-size(bits)>>
  end

  def write(pid, data, options \\ []) when is_pid(pid) and is_binary(data) and is_list(options),
    do: :ok

  def write_read(pid, data, bytes, options \\ [])
      when is_pid(pid) and is_binary(data) and is_byte_size(bytes) and is_list(options) do
    bits = bytes * 8
    <<0::unsigned-integer-size(bits)>>
  end

  def start_link(name, address, opts \\ [])
      when is_binary(name) and is_i2c_address(address) and is_list(opts),
      do: {:ok, self()}

  def release(pid) when is_pid(pid), do: :ok

  def detect_devices(bus) when is_binary(bus) or is_pid(bus), do: []
end
