defmodule Circuits.GPIO do
  import Wafer.Guards
  @moduledoc false

  def set_interrupts(ref, pin_condition, opts \\ [])
      when is_reference(ref) and is_pin_condition(pin_condition) and is_list(opts),
      do: :ok

  def open(pin_number, pin_direction, options \\ [])
      when is_pin_number(pin_number) and pin_direction in ~w[input output]a and is_list(options),
      do: {:ok, :erlang.make_ref()}

  def close(ref) when is_reference(ref), do: :ok
  def read(ref) when is_reference(ref), do: 0
  def write(ref, value) when is_reference(ref) and is_pin_value(value), do: :ok

  def set_direction(ref, direction) when is_reference(ref) and is_pin_direction(direction),
    do: :ok

  def set_pull_mode(ref, mode) when is_reference(ref) and is_pin_pull_mode(mode), do: :ok
end
