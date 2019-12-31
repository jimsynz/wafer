defmodule Wafer.Conn do
  @moduledoc """
  Defines a behaviour for connecting to a peripheral.

  This behaviour is used by all the driver types in `Wafer` and you should
  implement it for your devices also.

  ## Example

  Implementing `Conn` for a `HTS221` chip connected via Circuits' I2C driver.

  ```elixir
  defmodule HTS221 do
    defstruct ~w[conn]a
    alias Wafer.Drivers.CircuitsI2C, as: Driver
    @behaviour Wafer.Conn
    @default_bus "i2c-1"
    @default_address 0x5F

    def acquire(opts) when is_list(opts) do
      bus = Keyword.get(opts, :bus, @default_bus)
      address = Keyword.get(opts, :address, @default_address)
      with {:ok, conn} <- Driver.acquire(bus_name: bus, address: address),
          do: {:ok, %HTS221{conn: conn}}
    end

    def release(%HTS221{conn: conn}), do: Driver.release(conn)
  end
  ```
  """

  @type options :: [option]
  @type option :: {atom, any}

  @doc """
  Acquire a connection to a peripheral using the provided driver.
  """
  @callback acquire(options) :: t :: {:error, reason :: any}

  @doc """
  Release all resources associated with this connection.
  """
  @callback release(module) :: :ok | {:error, reason :: any}
end
