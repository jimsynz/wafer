defmodule Wafer.Driver.ElixirALEI2C do
  defstruct ~w[address bus pid]a
  @behaviour Wafer.Conn
  alias ElixirALE.I2C, as: Driver
  alias Wafer.I2C
  import Wafer.Guards

  @moduledoc """
  A connection to a chip via ElixirALE's I2C driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.Chip` and `Wafer.I2C` protocols.
  """

  @type t :: %__MODULE__{address: I2C.address(), bus: binary, pid: pid}

  @type options :: [option]
  @type option :: {:bus_name, binary} | {:address, I2C.address()}

  @doc """
  Acquire a connection to a peripheral using the ElixirALE I2C driver on the
  specified bus and address.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with bus when is_binary(bus) <- Keyword.get(opts, :bus_name),
         address when is_i2c_address(address) <- Keyword.get(opts, :address),
         {:ok, pid} <- Driver.start_link(bus, address),
         devices when is_list(devices) <- Driver.detect_devices(pid),
         true <- Keyword.get(opts, :force, false) || Enum.member?(devices, address) do
      {:ok, %__MODULE__{bus: bus, address: address, pid: pid}}
    else
      false ->
        {:error, "No device detected at address. Pass `force: true` to override."}

      :error ->
        {:error, "ElixirALE.I2C requires both `bus_name` and `address` options."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{pid: pid} = _conn) when is_pid(pid), do: ElixirALE.I2C.release(pid)
end

defimpl Wafer.Chip, for: Wafer.Driver.ElixirALEI2C do
  alias ElixirALE.I2C, as: Driver
  import Wafer.Guards

  def read_register(%{pid: pid}, register_address, bytes)
      when is_pid(pid) and is_register_address(register_address) and is_byte_size(bytes) do
    case Driver.write_read(pid, <<register_address>>, bytes) do
      data when is_binary(data) -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def read_register(_conn, _register_address, _bytes), do: {:error, "Invalid argument"}

  def write_register(%{pid: pid} = conn, register_address, data)
      when is_pid(pid) and is_register_address(register_address) and is_binary(data) do
    case Driver.write(pid, <<register_address, data::binary>>) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
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

defimpl Wafer.I2C, for: Wafer.Driver.ElixirALEI2C do
  import Wafer.Guards
  alias ElixirALE.I2C, as: Driver

  def read(%{pid: pid}, bytes, options \\ [])
      when is_pid(pid) and is_byte_size(bytes) and is_list(options) do
    case Driver.read(pid, bytes) do
      data when is_binary(data) -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%{pid: pid} = conn, data, options \\ [])
      when is_pid(pid) and is_binary(data) and is_list(options) do
    case Driver.write(pid, data) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def write_read(%{pid: pid} = conn, data, bytes, options \\ [])
      when is_pid(pid) and is_binary(data) and is_byte_size(bytes) and is_list(options) do
    case Driver.write_read(pid, data, bytes) do
      data when is_binary(data) -> {:ok, data, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def detect_devices(%{pid: pid}) do
    case Driver.detect_devices(pid) do
      devices when is_list(devices) -> {:ok, devices}
      {:error, reason} -> {:error, reason}
    end
  end
end
