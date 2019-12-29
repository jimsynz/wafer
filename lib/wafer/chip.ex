defprotocol Wafer.Chip do
  alias Wafer.Conn

  @moduledoc """
  A `Chip` is a physical peripheral with registers which can be read from and
  written to.
  """

  @type i2c_address :: 0..0x7F
  @type register_address :: non_neg_integer
  @type bytes :: non_neg_integer

  @doc """
  Read the register at the specified address.

  ## Arguments

    - `conn` a type which implements the `Wafer.Conn` behaviour.
    - `register_address` the address of the register to read from.
    - `bytes` the number of bytes to read from the register.

  ## Example

      iex> {:ok, conn} = ElixirAleI2C.acquire(bus: "i2c-1", address: 0x68)
      ...> Chip.read_register(conn, 0, 1)
      {:ok, <<0>>}
  """
  @spec read_register(Conn.t(), register_address, bytes) ::
          {:ok, data :: binary} | {:error, reason :: any}
  def read_register(conn, register_address, bytes)

  @doc """
  Write to the register at the specified address.

  ## Arguments

    - `conn` a type which implements the `Wafer.Conn` behaviour.
    - `register_address` the address of the register to write to.
    - `data` a bitstring or binary of data to write to the register.

  ## Example

      iex> {:ok, conn} = ElixirAleI2C.acquire(bus: "i2c", address: 0x68)
      ...> Chip.write_register(conn, 0, <<0>>)
      :ok
  """
  @spec write_register(Conn.t(), register_address, data :: binary) ::
          :ok | {:error, reason :: any}
  def write_register(conn, register_address, data)

  @doc """
  Perform a swap with the register at the specified address.  With some drivers
  this is atomic, and with others it is implemented as a register read followed
  by a write.

  ## Arguments

    - `conn` a type which implements the `Wafer.Conn` behaviour.
    - `register_address` the address of the register to swap.
    - `new_data` the data to write to the regsiter.

  ## Returns

  The data that was previously in the register.

  ## Example

      iex> {:ok, conn} = ElixirAleI2C.acquire(bus: "i2c", address: 0x68)
      ...> Chip.swap_register(conn, 0, <<1>>)
      {:ok, <<0>>}
  """
  @spec swap_register(Conn.t(), register_address, new_data :: binary) ::
          {:ok, data :: binary} | {:error, reason :: any}
  def swap_register(conn, register_address, new_data)
end
