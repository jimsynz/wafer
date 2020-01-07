defprotocol Wafer.Chip do
  alias Wafer.Conn

  @moduledoc """
  A `Chip` is a physical peripheral with registers which can be read from and
  written to.

  Rather than interacting with this protocol directly, it's a lot easier to use
  the macros in `Wafer.Registers` to do it for you.

  ## Deriving

  If you're implementing your own `Conn` type which simply delegates to one of
  the lower level drivers then you can derive this protocol automatically:

  ```elixir
  defmodule MyConnection do
    @derive Wafer.Chip
    defstruct [:conn]
  end
  ```

  If your type uses a key other than `conn` for the inner connection you can
  specify it while deriving:

  ```elixir
  defmodule MyConnection do
    @derive {Wafer.Chip, key: :i2c_conn}
    defstruct [:i2c_conn]
  end
  ```

  """

  @type register_address :: non_neg_integer
  @type bytes :: non_neg_integer

  @doc """
  Read the register at the specified address.

  ## Arguments

    - `conn` a type which implements the `Wafer.Conn` behaviour.
    - `register_address` the address of the register to read from.
    - `bytes` the number of bytes to read from the register.

  ## Example

      iex> {:ok, conn} = ElixirALE.I2C.acquire(bus: "i2c-1", address: 0x68)
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

      iex> {:ok, conn} = ElixirALE.I2C.acquire(bus: "i2c", address: 0x68)
      ...> Chip.write_register(conn, 0, <<0>>)
      {:ok, conn}
  """
  @spec write_register(Conn.t(), register_address, data :: binary) ::
          {:ok, t} | {:error, reason :: any}
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

      iex> {:ok, conn} = ElixirALE.I2C.acquire(bus: "i2c", address: 0x68)
      ...> Chip.swap_register(conn, 0, <<1>>)
      {:ok, <<0>>, conn}
  """
  @spec swap_register(Conn.t(), register_address, new_data :: binary) ::
          {:ok, data :: binary, t} | {:error, reason :: any}
  def swap_register(conn, register_address, new_data)
end

defimpl Wafer.Chip, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.Chip` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.Chip, for: unquote(module) do
        import Wafer.Guards
        alias Wafer.Chip

        def read_register(%{unquote(key) => inner_conn}, register_address, bytes)
            when is_register_address(register_address) and is_byte_size(bytes),
            do: Chip.read_register(inner_conn, register_address, bytes)

        def write_register(%{unquote(key) => inner_conn} = conn, register_address, data)
            when is_register_address(register_address) and is_binary(data) do
          with {:ok, inner_conn} <- Chip.write_register(inner_conn, register_address, data),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def swap_register(%{unquote(key) => inner_conn} = conn, register_address, new_data) do
          with {:ok, data, inner_conn} <-
                 Chip.swap_register(inner_conn, register_address, new_data),
               do: {:ok, data, Map.put(conn, unquote(key), inner_conn)}
        end
      end
    end
  end

  def read_register(unknown, _register_address, _bytes),
    do: {:error, "`Wafer.Chip` not implemented for `#{inspect(unknown)}`"}

  def write_register(unknown, _register_address, _data),
    do: {:error, "`Wafer.Chip` not implemented for `#{inspect(unknown)}`"}

  def swap_register(unknown, _register_address, _new_data),
    do: {:error, "`Wafer.Chip` not implemented for `#{inspect(unknown)}`"}
end
