defprotocol Wafer.I2C do
  alias Wafer.Conn

  @moduledoc """
  A protocol for interacting with I2C devices directly.  Most of the time you'll
  want to use the `Chip` protocol for working with registers, but this is
  provided for consistency's sake.
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
