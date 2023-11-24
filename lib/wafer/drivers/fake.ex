defmodule Wafer.Driver.Fake do
  defstruct ~w[opts]a
  @behaviour Wafer.Conn
  require Logger

  @moduledoc """
  This module provides a fake driver which you can use in your tests.

  It doesn't really do anything except return zeroes or empty results.  I
  suggest that you [use Mimic](https://hex.pm/packages/mimic) to set
  expectations for function calls and mock return values.

  This module implements the `Chip`, `DeviceID`, `GPIO`, `I2C` and `SPI`
  protocols.
  """

  @impl Wafer.Conn
  def acquire(opts) do
    if emit_warning(),
      do: Logger.warning("Creating an instance of `Wafer.Driver.Fake` in a non-test environment.")

    {:ok, %__MODULE__{opts: opts}}
  end

  defp emit_warning do
    :wafer
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:warn, false)
  end
end

defimpl Wafer.Release, for: Wafer.Driver.Fake do
  def release(%Wafer.Driver.Fake{}), do: :ok
end

defimpl Wafer.Chip, for: Wafer.Driver.Fake do
  import Wafer.Guards

  def read_register(_conn, address, bytes)
      when is_register_address(address) and is_byte_size(bytes) do
    bits = bytes * 8
    {:ok, <<address::size(bits)>>}
  end

  def write_register(conn, address, data) when is_register_address(address) and is_binary(data),
    do: {:ok, conn}

  def swap_register(conn, address, data)
      when is_register_address(address) and is_binary(data) do
    bits = bit_size(data)
    {:ok, <<address::size(bits)>>, conn}
  end
end

defimpl Wafer.DeviceID, for: Wafer.Driver.Fake do
  def id(conn), do: conn
end

defimpl Wafer.GPIO, for: Wafer.Driver.Fake do
  import Wafer.Guards

  def read(conn), do: {:ok, 0, conn}
  def write(conn, value) when is_pin_value(value), do: {:ok, conn}
  def direction(conn, pin_direction) when is_pin_direction(pin_direction), do: {:ok, conn}

  def enable_interrupt(conn, pin_condition, _metadata \\ nil)
      when is_pin_condition(pin_condition),
      do: {:ok, conn}

  def disable_interrupt(conn, pin_condition) when is_pin_condition(pin_condition), do: {:ok, conn}

  def pull_mode(conn, pull_mode) when is_pin_pull_mode(pull_mode), do: {:ok, conn}
end

defimpl Wafer.I2C, for: Wafer.Driver.Fake do
  import Wafer.Guards

  def read(_conn, bytes, _options \\ []) when is_byte_size(bytes) do
    bits = bytes * 8
    {:ok, <<0::size(bits)>>}
  end

  def write(conn, data, _options \\ []) when is_binary(data), do: {:ok, conn}

  def write_read(conn, data, bytes, _options \\ []) when is_binary(data) do
    bits = bytes * 8
    {:ok, <<0::size(bits)>>, conn}
  end

  def detect_devices(_conn), do: {:ok, []}
end

defimpl Wafer.SPI, for: Wafer.Driver.Fake do
  def transfer(conn, data) when is_binary(data) do
    bits = bit_size(data)
    {:ok, <<0::size(bits)>>, conn}
  end
end
