defprotocol Wafer.SPI do
  alias Wafer.Conn

  @moduledoc """
  A (very simple) protocol for interacting with SPI connected devices.

  This API is a minimal version of the `Circuits.SPI` APIs, except that it takes
  a `Conn` which implements `SPI` as an argument.  If you want to use any
  advanced features, such as bus detection, I advise you to interact with the
  underlying driver directly.

  ## Deriving

  If you're implementing your own `Conn` type that simply delegates to one of
  the lower level drivers then you can derive this protocol automatically:

  ```elixir
  defstruct MySPIDevice do
    @derive Wafer.SPI
    defstruct [:conn]
  end
  ```

  If your type uses a key other than `conn` for the inner connection you can
  specify it while deriving:

  ```elixir
  defstruct MySPIDevice do
    @derive {Wafer.SPI, key: :spi_conn}
    defstruct [:spi_conn]
  end
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

defimpl Wafer.SPI, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.SPI` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.SPI, for: unquote(module) do
        import Wafer.Guards
        alias Wafer.SPI

        def transfer(%{unquote(key) => inner_conn} = conn, data)
            when is_binary(data) do
          with {:ok, data, inner_conn} <- SPI.transfer(inner_conn, data),
               do: {:ok, data, Map.put(conn, unquote(key), inner_conn)}
        end
      end
    end
  end

  def transfer(unknown, _data),
    do: {:error, "`Wafer.SPI` not implemented for `#{inspect(unknown)}`"}
end
