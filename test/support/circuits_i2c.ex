defmodule Circuits.I2C do
  import Wafer.Guards
  @moduledoc false

  def read(ref, address, bytes, opts \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_byte_size(bytes) and is_list(opts) do
    bits = bytes * 8
    {:ok, <<0::unsigned-integer-size(bits)>>}
  end

  def write_read(ref, address, data, bytes, opts \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_binary(data) and
             is_byte_size(bytes) and is_list(opts) do
    bits = bytes * 8
    {:ok, <<0::unsigned-integer-size(bits)>>}
  end

  def write(ref, address, data, opts \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_binary(data) and is_list(opts),
      do: :ok

  def open(name) when is_binary(name), do: {:ok, :erlang.make_ref()}
  def close(ref) when is_reference(ref), do: :ok

  def detect_devices(bus) when is_reference(bus) or is_binary(bus), do: []
end
