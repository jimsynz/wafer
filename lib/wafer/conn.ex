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
    alias Wafer.Drivers.Circuits.I2C, as: Driver
    @behaviour Wafer.Conn
    @default_bus "i2c-1"
    @default_address 0x5F

    def acquire(opts) when is_list(opts) do
      bus = Keyword.get(opts, :bus, @default_bus)
      address = Keyword.get(opts, :address, @default_address)
      with {:ok, conn} <- Driver.acquire(bus_name: bus, address: address),
          do: {:ok, %HTS221{conn: conn}}
    end
  end
  ```
  """

  defmacro __using__(_env) do
    quote do
      @behaviour Wafer.Conn
    end

    Protocol.assert_impl!(Wafer.Release, __MODULE__)
  end

  @type t :: any
  @type options :: [option]
  @type option :: {atom, any}

  @doc """
  Acquire a connection to a peripheral using the provided driver.
  """
  @callback acquire(options) :: {:ok, t} | {:error, reason :: any}
end
