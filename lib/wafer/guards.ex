defmodule Wafer.Guards do
  @moduledoc """
  Handy guards which you can use in your code to assert correct values.
  """

  @doc "A positive integer"
  defguard is_pin_number(pin) when is_integer(pin) and pin >= 0

  @doc "Either `:in` or `:out`"
  defguard is_pin_direction(direction) when direction in ~w[in out]a

  @doc "One of `:none`, `:rising`, `:falling` or `:both`"
  defguard is_pin_condition(condition) when condition in ~w[none rising falling both]a

  @doc "Either `0` or `1`"
  defguard is_pin_value(value) when value in [0, 1]

  @doc "One of `:not_set`, `:none`, `:pull_up` or `:pull_down`"
  defguard is_pin_pull_mode(mode) when mode in ~w[not_set none pull_up pull_down]a

  @doc "An integer between `0` and `0x7F`"
  defguard is_i2c_address(address) when is_integer(address) and address >= 0 and address <= 0x7F

  @doc "A positive integer"
  defguard is_register_address(address) when is_integer(address) and address >= 0

  @doc "A positive integer"
  defguard is_byte_size(bytes) when is_integer(bytes) and bytes >= 0
end
