defprotocol Wafer.SPI do
  alias Wafer.Conn

  @moduledoc """
  A (very simple) protocol for interacting with SPI connected devices.
  """

  @type data :: binary

  @doc """
  Perform an SPI transfer.

  SPI transfers are synchronous, so `data` should be a binary of bytes to send
  to the device, and you will receive back a binary of the same length
  containing the data received from the device.
  """
  @spec transfer(Conn.t(), data) :: {:ok, data, Conn.t()} | {:error, reason :: any}
  def transfer(conn, data)
end
