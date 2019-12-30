# Wafer

Wafer is an OTP application that assists with writing drivers for peripherals using I2C, SPI and GPIO pins.

Wafer provides Elixir protocols for interacting with device registers and dealing with GPIO, so that you can use directly connected hardware GPIO pins or GPIO expanders such as the [MCP23008](https://www.microchip.com/wwwproducts/en/MCP23008) or the [CD74HC595](http://www.ti.com/product/CD74HC595) SPI shift register.

Wafer implements the [GPIO](https://hexdocs.pm/wafer/Wafer.GPIOProto.html) and [Chip](https://hexdocs.pm/wafer/Wafer.Chip.html) protocols for [ElixirALE](https://hex.pm/packages/elixir_ale)'s GPIO and I2C drivers, [Circuits.GPIO](https://hex.pm/packages/circuits_gpio) and [Circuits.I2C](https://hex.pm/packages/circuits_i2c).  Implementing it for SPI should also be trivial, I just don't have any SPI devices to test with at the moment.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wafer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wafer, "~> 0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wafer](https://hexdocs.pm/wafer).

