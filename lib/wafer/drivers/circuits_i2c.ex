defmodule Wafer.Driver.CircuitsI2C do
  defstruct ~w[address bus ref]a
  @behaviour Wafer.Conn
  alias Circuits.I2C, as: Driver
  alias Wafer.Chip

  @moduledoc """
  A connection to a chip via Circuits' I2C driver.
  """

  @type t :: %__MODULE__{address: Chip.i2c_address(), bus: binary, ref: reference}

  @doc """
  Acquire a connection to a peripheral using the Circuits' I2C driver on the specified bus and address.
  """
  @spec acquire(bus_name: binary, address: Chip.i2c_address()) ::
          {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, bus} <- Keyword.get(opts, :bus_name),
         {:ok, address} <- Keyword.get(opts, :address),
         {:ok, ref} <- Driver.open(bus) do
      {:ok, %__MODULE__{bus: bus, address: address, ref: ref}}
    else
      :error -> {:error, "Circuits.I2C requires both the `bus_name` and `address` options."}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%{ref: ref}), do: Circuits.I2C.close(ref)
end

defimpl Wafer.Chip, for: Wafer.Driver.CircuitsI2C do
  alias Circuits.I2C, as: Driver

  def read_register(%{ref: ref, address: address}, register_address, bytes),
    do: Driver.write_read(ref, address, <<register_address>>, bytes)

  def read_register(_conn, _register_address, _bytes), do: {:error, "Invalid argument"}

  def write_register(%{ref: ref, address: address}, register_address, data),
    do: Driver.write(ref, address, <<register_address, data>>)

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
