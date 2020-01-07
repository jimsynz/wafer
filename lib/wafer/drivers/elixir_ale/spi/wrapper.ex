defmodule Wafer.Driver.ElixirALE.SPI.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate child_spec(arg), to: ElixirALE.SPI

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate device_names(), to: ElixirALE.SPI

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate init(arg), to: ElixirALE.SPI

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate release(pid), to: ElixirALE.SPI

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate start_link(devname, spi_opts \\ [], opts \\ []), to: ElixirALE.SPI

  @compile {:no_warn_undefined, ElixirALE.SPI}
  defdelegate transfer(pid, data), to: ElixirALE.SPI
end
