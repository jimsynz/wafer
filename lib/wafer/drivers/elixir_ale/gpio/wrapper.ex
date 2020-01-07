defmodule Wafer.Driver.ElixirALE.GPIO.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate child_spec(arg), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate init(list), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate pin(pid), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate read(pid), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate release(pid), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate set_int(pid, direction), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate start_link(pin, pin_direction, opts \\ []), to: ElixirALE.GPIO

  @compile {:no_warn_undefined, ElixirALE.GPIO}
  defdelegate write(pid, value), to: ElixirALE.GPIO
end
