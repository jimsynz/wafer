defmodule Wafer.Driver.Circuits.SPI.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, Circuits.SPI}
  defdelegate bus_names(), to: Circuits.SPI

  @compile {:no_warn_undefined, Circuits.SPI}
  defdelegate close(spi_bus), to: Circuits.SPI

  @compile {:no_warn_undefined, Circuits.SPI}
  defdelegate info(), to: Circuits.SPI

  @compile {:no_warn_undefined, Circuits.SPI}
  defdelegate open(bus_name, options \\ []), to: Circuits.SPI

  @compile {:no_warn_undefined, Circuits.SPI}
  defdelegate transfer(spi_bus, data), to: Circuits.SPI
end
