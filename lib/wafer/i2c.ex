defprotocol Wafer.I2C do
  alias Wafer.Conn

  @moduledoc """
  A protocol for interacting with I2C devices directly.  Most of the time you'll
  want to use the `Chip` protocol for working with registers, but this is
  provided for consistency's sake.

  This API is extremely similar to the `ElixirALE.I2C` and `Circuits.I2C` APIs,
  except that it takes a `Conn` which implements `I2C` as an argument.

  ## Deriving

  If you're implementing your own `Conn` type that simply delegates to one of
  the lower level drivers then you can derive this protocol automatically:

  ```elixir
  defstruct MyI2CDevice do
    @derive Wafer.I2C
    defstruct [:conn]
  end
  ```

  If your type uses a key other than `conn` for the inner connection you can
  specify it while deriving:

  ```elixir
  defstruct MyI2CDevice do
    @derive {Wafer.I2C, key: :i2c_conn}
    defstruct [:i2c_conn]
  end
  """

  @type address :: 0..0x7F

  # See the documentation to the underlying driver for information about which options are supported.
  @type options :: [option]
  @type option :: any

  @type data :: binary

  @doc """
  Initiate a read transaction to the connection's I2C device.
  """
  @spec read(Conn.t(), non_neg_integer, options) ::
          {:ok, data} | {:error, reason :: any}
  def read(conn, bytes_to_read, options \\ [])

  @doc """
  Write `data` to the connection's I2C device.
  """
  @spec write(Conn.t(), data, options) ::
          {:ok, Conn.t()} | {:error, reason :: any}
  def write(conn, data, options \\ [])

  @doc """
  Write data to an I2C device and then immediately issue a read.
  """
  @spec write_read(Conn.t(), data, non_neg_integer, options) ::
          {:ok, data, Conn.t()} | {:error, reason :: any}
  def write_read(conn, data, bytes_to_read, options \\ [])

  @doc """
  Detect the devices adjacent to the connection's device on the same I2C bus.
  """
  @spec detect_devices(Conn.t()) :: {:ok, [address]}
  def detect_devices(conn)
end

defimpl Wafer.I2C, for: Any do
  # credo:disable-for-next-line
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.I2C` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.I2C, for: unquote(module) do
        import Wafer.Guards
        alias Wafer.I2C

        def read(%{unquote(key) => inner_conn}, bytes_to_read, options \\ [])
            when is_byte_size(bytes_to_read) and is_list(options) do
          I2C.read(inner_conn, bytes_to_read, options)
        end

        def write(%{unquote(key) => inner_conn} = conn, data, options \\ [])
            when is_binary(data) and is_list(options) do
          with {:ok, inner_conn} <- I2C.write(inner_conn, data, options),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def write_read(%{unquote(key) => inner_conn} = conn, data, bytes_to_read, options \\ [])
            when is_binary(data) and is_byte_size(bytes_to_read) and is_list(options) do
          with {:ok, data, inner_conn} <-
                 I2C.write_read(inner_conn, data, bytes_to_read, options),
               do: {:ok, data, Map.put(conn, unquote(key), inner_conn)}
        end

        def detect_devices(%{unquote(key) => inner_conn}), do: I2C.detect_devices(inner_conn)
      end
    end
  end

  def read(unknown, _bytes_to_read, _options \\ []),
    do: {:error, "`Wafer.I2C` not implemented for `#{inspect(unknown)}`"}

  def write(unknown, _data, _options \\ []),
    do: {:error, "`Wafer.I2C` not implemented for `#{inspect(unknown)}`"}

  def write_read(unknown, _data, _bytes_to_read, _options \\ []),
    do: {:error, "`Wafer.I2C` not implemented for `#{inspect(unknown)}`"}

  def detect_devices(unknown),
    do: {:error, "`Wafer.I2C` not implemented for `#{inspect(unknown)}`"}
end
