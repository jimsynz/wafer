# Wafer

Wafer is an OTP application that assists with writing drivers for peripherals using I2C, SPI and GPIO pins.

Wafer provides Elixir protocols for interacting with device registers and dealing with GPIO, so that you can use directly connected hardware GPIO pins or GPIO expanders such as the [MCP23008](https://www.microchip.com/wwwproducts/en/MCP23008) or the [CD74HC595](http://www.ti.com/product/CD74HC595) SPI shift register.

Wafer implements the [GPIO](https://hexdocs.pm/wafer/Wafer.GPIOProto.html) and [Chip](https://hexdocs.pm/wafer/Wafer.Chip.html) protocols for [ElixirALE](https://hex.pm/packages/elixir_ale)'s GPIO and I2C drivers, [Circuits.GPIO](https://hex.pm/packages/circuits_gpio) and [Circuits.I2C](https://hex.pm/packages/circuits_i2c).  Implementing it for SPI should also be trivial, I just don't have any SPI devices to test with at the moment.

Documentation for the master branch can always be found [here](https://jimsy.gitlab.io/wafer/).

Some examples of how to use this project:
 - [Augie](https://gitlab.com/jimsy/augie), a hexapod robot.
 - [PCA9641](https://gitlab.com/jimsy/pca9641), an example of how easy it is to write a driver with Wafer.

## Working with registers

Wafer provides the very helpful [Registers](https://hexdocs.pm/wafer/Wafer.Registers.html) macros which allow you to quickly and easily define your registers for your device:

Here's a very simple example:

```elixir
defmodule HTS221.Registers do
  use Wafer.Registers

  defregister(:ctrl_reg1, 0x20, :rw, 1)
  defregister(:humidity_out_l, 0x28, :ro, 1)
  defregister(:humidity_out_h, 0x29, :ro, 1)
end

defmodule HTS221 do
  import HTS221.Registers
  use Bitwise

  def humidity(conn) do
    with {:ok, <<msb>>} <- read_humidity_out_h(conn),
         {:ok, <<lsb>} <- read_humidity_out_l(conn),
         do: {:ok, msb <<< 8 + lsb}
  end

  def on?(conn) do
    case read_ctrl_reg1(conn) do
      {:ok, <<1::integer-size(1), _::bits>>} -> true
      _ -> false
    end
  end

  def turn_on(conn), do: write_ctrl_reg1(conn, <<1::integer-size(1), 0::integer-size(7)>>)
  def turn_off(conn), do: write_ctrl_reg1(conn, <<0>>)
end
```

## Working with GPIO

Wafer provides a simple way to drive specific GPIO functionality per device.

Here's a super simple "blinky" example:

```elixir
defmodule WaferBlinky do
  @derive [Wafer.GPIO]
  defstruct ~w[conn]a
  @behaviour Wafer.Conn
  alias Wafer.Conn
  alias Wafer.GPIO

  @type t :: %WaferBlinky{conn: Conn.t()}
  @type acquire_options :: [acquire_option]
  @type acquire_option :: {:conn, Conn.t()}

  @impl Wafer.Conn
  def acquire(options) do
    with {:ok, conn} <- Keyword.fetch(options, :conn) do
      {:ok, %WaferBlinky{conn: conn}}
    else
      :error -> {:error, "`WaferBlinky.acquire/1` requires the `conn` option."}
      {:error, reason} -> {:error, reason}
    end
  end

  def turn_on(conn), do: GPIO.write(conn, 1)
  def turn_off(conn), do: GPIO.write(conn, 0)
end
```

And a simple mix task to drive it:

```elixir
defmodule Mix.Tasks.Blink do
  use Mix.Task
  @shortdoc "GPIO LED Blink Example"

  alias Wafer.Driver.Circuits.GPIO

  def run(_args) do
    {:ok, led_pin_21} = GPIO.acquire(pin: 21, direction: :out)
    {:ok, conn} = WaferBlinky.acquire(conn: led_pin_21)

    Enum.each(1..10, fn _ ->
      WaferBlinky.turn_on(conn)
      :timer.sleep(500)
      WaferBlinky.turn_off(conn)
      :timer.sleep(500)
    end)
  end
end
```

## Running the tests

I've included stub implementations of the parts of `ElixirALE` and `Circuits`
that are interacted with by this project, so the tests should run and pass on
machines without physical hardware interfaces.  If you have a Raspberry Pi with
a Pi Sense Hat connected you can run the tests with the `SENSE_HAT_PRESENT=true`
environment variable set and it will perform integration tests with two of the
sensors on this device.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wafer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wafer, "~> 0.1.6"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wafer](https://hexdocs.pm/wafer).

