defmodule Wafer.Driver.ElixirAleI2C do
  defstruct ~w[address bus pid]a
  @behaviour Wafer.Conn
  alias ElixirALE.I2C, as: Driver
  alias Wafer.Chip

  @moduledoc """
  A connection to a chip via ElixirALE's I2C driver.
  """

  @type t :: %__MODULE__{address: Chip.i2c_address(), bus: binary, pid: pid}

  @type options :: [option]
  @type option :: {:bus_name, binary} | {:address, Chip.i2c_address()}

  @doc """
  Acquire a connection to a peripheral using the ElixirALE I2C driver on the
  specified bus and address.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, bus} <- Keyword.get(opts, :bus_name),
         {:ok, address} <- Keyword.get(opts, :address),
         {:ok, pid} <- Driver.start_link(bus, address) do
      {:ok, %__MODULE__{bus: bus, address: address, pid: pid}}
    else
      :error -> {:error, "ElixirALE.I2C requires both `bus_name` and `address` options."}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%{pid: pid}), do: ElixirALE.I2C.release(pid)
end

defimpl Wafer.Chip, for: Wafer.Driver.ElixirAleI2C do
  alias ElixirALE.I2C, as: Driver

  def read_register(%{pid: pid}, register_address, bytes)
      when is_integer(register_address) and register_address >= 0 and is_integer(bytes) and
             bytes >= 0 do
    case Driver.write_read(pid, <<register_address>>, bytes) do
      data when is_binary(data) -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def read_register(_conn, _register_address, _bytes), do: {:error, "Invalid argument"}

  def write_register(%{pid: pid}, register_address, data)
      when is_integer(register_address) and register_address >= 0 and is_binary(data),
      do: Driver.write(pid, <<register_address, data>>)

  def write_register(_conn, _register_address, _data), do: {:error, "Invalid argument"}

  def swap_register(conn, register_address, data)
      when is_integer(register_address) and register_address >= 0 and is_binary(data) do
    with {:ok, old_data} <- read_register(conn, register_address, byte_size(data)),
         :ok <- write_register(conn, register_address, data) do
      {:ok, old_data}
    end
  end

  def swap_register(_conn, _register_address, _data), do: {:error, "Invalid argument"}
end
