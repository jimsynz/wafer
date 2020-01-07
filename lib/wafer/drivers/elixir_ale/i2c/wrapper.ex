defmodule Wafer.Driver.ElixirALE.I2C.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate child_spec(arg), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate detect_devices(pid_or_devname), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate device_names(), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate init(list), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate read(pid, count), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate read_device(pid, address, count), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate release(pid), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate start_link(devname, address, opts \\ []), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate write(pid, data), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate write_device(pid, address, data), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate write_read(pid, write_data, read_count), to: ElixirALE.I2C

  @compile {:no_warn_undefined, ElixirALE.I2C}
  defdelegate write_read_device(pid, address, write_data, read_count), to: ElixirALE
end
