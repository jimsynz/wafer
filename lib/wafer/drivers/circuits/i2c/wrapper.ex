defmodule Wafer.Driver.Circuits.I2C.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate bus_names(), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate close(i2c_bus), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate detect_devices(), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate detect_devices(i2c_bus), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate info(), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate open(bus_name), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate read(i2c_bus, address, bytes_to_read, opts \\ []), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate read!(i2c_bus, address, bytes_to_read, opts \\ []), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate write(i2c_bus, address, data, opts \\ []), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate write!(i2c_bus, address, data, opts \\ []), to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate write_read(i2c_bus, address, write_data, bytes_to_read, opts \\ []),
    to: Circuits.I2C

  @compile {:no_warn_undefined, Circuits.I2C}
  defdelegate write_read!(i2c_bus, address, write_data, bytes_to_read, opts \\ []),
    to: Circuits.I2C
end
