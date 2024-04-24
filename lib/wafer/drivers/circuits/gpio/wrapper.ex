defmodule Wafer.Driver.Circuits.GPIO.Wrapper do
  @moduledoc false

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate close(gpio), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate backend_info(gpio \\ nil), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate open(pin_number, pin_direction, options \\ []), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate identifiers(gpio), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate read(gpio), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate set_direction(gpio, pin_direction), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate set_interrupts(gpio, trigger, opts \\ []), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate set_pull_mode(gpio, pull_mode), to: Circuits.GPIO

  @compile {:no_warn_undefined, Circuits.GPIO}
  defdelegate write(gpio, value), to: Circuits.GPIO
end
