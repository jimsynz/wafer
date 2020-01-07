defmodule Wafer.Driver.Circuits.I2C do
  defstruct ~w[address bus ref]a
  @behaviour Wafer.Conn
  alias Wafer.Driver.Circuits.I2C.Wrapper
  alias Wafer.I2C
  import Wafer.Guards

  @moduledoc """
  A connection to a chip via Circuits' I2C driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.Chip` and `Wafer.I2C` protocols.
  """

  @type t :: %__MODULE__{address: I2C.address(), bus: binary, ref: reference}
  @type options :: [option]
  @type option :: {:bus_name, binary} | {:address, I2C.address()} | {:force, boolean}

  @doc """
  Acquire a connection to a peripheral using the Circuits' I2C driver on the
  specified bus and address.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, bus} when is_binary(bus) <- Keyword.fetch(opts, :bus_name),
         {:ok, address} when is_i2c_address(address) <- Keyword.fetch(opts, :address),
         {:ok, ref} when is_reference(ref) <- Wrapper.open(bus),
         devices when is_list(devices) <- Wrapper.detect_devices(ref),
         true <- Keyword.get(opts, :force, false) || Enum.member?(devices, address) do
      {:ok, %__MODULE__{bus: bus, address: address, ref: ref}}
    else
      false ->
        {:error, "No device detected at address. Pass `force: true` to override."}

      :error ->
        {:error, "Circuits.I2C requires both the `bus_name` and `address` options."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{ref: ref} = _conn), do: Wrapper.close(ref)
end

defimpl Wafer.Chip, for: Wafer.Driver.Circuits.I2C do
  alias Wafer.Driver.Circuits.I2C.Wrapper
  import Wafer.Guards

  def read_register(%{ref: ref, address: address}, register_address, bytes)
      when is_reference(ref) and is_i2c_address(address) and is_register_address(register_address) and
             is_byte_size(bytes),
      do: Wrapper.write_read(ref, address, <<register_address>>, bytes)

  def read_register(_conn, _register_address, _bytes), do: {:error, "Invalid argument"}

  def write_register(%{ref: ref, address: address} = conn, register_address, data)
      when is_reference(ref) and is_i2c_address(address) and is_register_address(register_address) and
             is_binary(data) do
    with :ok <- Wrapper.write(ref, address, <<register_address, data::binary>>), do: {:ok, conn}
  end

  def write_register(_conn, _register_address, _data), do: {:error, "Invalid argument"}

  def swap_register(conn, register_address, data)
      when is_register_address(register_address) and is_binary(data) do
    with {:ok, old_data} <- read_register(conn, register_address, byte_size(data)),
         {:ok, conn} <- write_register(conn, register_address, data) do
      {:ok, old_data, conn}
    end
  end

  def swap_register(_conn, _register_address, _data), do: {:error, "Invalid argument"}
end

defimpl Wafer.I2C, for: Wafer.Driver.Circuits.I2C do
  import Wafer.Guards
  alias Wafer.Driver.Circuits.I2C.Wrapper

  def read(%{ref: ref, address: address}, bytes, options \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_byte_size(bytes) and
             is_list(options) do
    case Wrapper.read(ref, address, bytes, options) do
      {:ok, data} when is_binary(data) and byte_size(data) == bytes -> {:ok, data}
      {:error, reason} -> {:error, reason}
      other -> {:error, "Invalid response from driver: #{inspect(other)}"}
    end
  end

  def write(%{ref: ref, address: address} = conn, data, options \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_binary(data) and is_list(options) do
    with :ok <- Wrapper.write(ref, address, data, options), do: {:ok, conn}
  end

  def write_read(%{ref: ref, address: address} = conn, data, bytes, options \\ [])
      when is_reference(ref) and is_i2c_address(address) and is_binary(data) and
             is_byte_size(bytes) and is_list(options) do
    case Wrapper.write_read(ref, address, data, bytes, options) do
      {:ok, data} when is_binary(data) and byte_size(data) == bytes -> {:ok, data, conn}
      {:error, reason} -> {:error, reason}
      other -> {:error, "Invalid response from driver: #{inspect(other)}"}
    end
  end

  def detect_devices(%{ref: ref}) when is_reference(ref) do
    case Wrapper.detect_devices(ref) do
      devices when is_list(devices) -> {:ok, devices}
      {:error, reason} -> {:error, reason}
      other -> {:error, "Invalid response from driver: #{inspect(other)}"}
    end
  end
end

defimpl Wafer.DeviceID, for: Wafer.Driver.Circuits.I2C do
  def id(%{address: address, bus: bus}), do: {Wafer.Driver.Circuits.I2C, bus, address}
end
