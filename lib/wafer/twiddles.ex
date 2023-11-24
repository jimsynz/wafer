defmodule Wafer.Twiddles do
  import Bitwise

  @moduledoc """
  Handy functions for dealing with bits and bytes in the wild.
  """

  @type bit_number :: 0..7
  @type bit :: 0..1
  @type single_byte_binary :: <<_::8>>

  # Verify that an integer value fits within a 1 byte representation.
  defguard is_byte(byte) when is_integer(byte) and byte >= 0 and byte <= 255

  # Verify that an integer value is between `0` and `7`.
  defguard is_bit_number(bit) when is_integer(bit) and bit >= 0 and bit <= 7

  # Verify that a bit is actually a bit (ie `0` or `1`).
  defguard is_bit(bit) when bit in [0, 1]

  @doc """
  Set a the specified `bit_number` to `1` within the `byte`.

  ## Example

      iex> set_bit(0, 0)
      1

      iex> set_bit(<<0>>, 0)
      <<1>>
  """
  @spec set_bit(byte | single_byte_binary, bit_number) :: byte
  def set_bit(byte, bit_number) when is_byte(byte) and is_bit_number(bit_number),
    do: byte ||| 1 <<< bit_number

  def set_bit(<<byte>>, bit_number), do: <<set_bit(byte, bit_number)>>

  @doc """
  Set the specified `bit` to `0` within the `byte`.

  ## Example

      iex> clear_bit(3, 0)
      2

      iex> clear_bit(<<3>>, 0)
      <<2>>
  """
  @spec clear_bit(byte | single_byte_binary, bit_number) :: byte
  def clear_bit(byte, bit_number) when is_byte(byte) and is_bit_number(bit_number),
    do: byte &&& ~~~(1 <<< bit_number)

  def clear_bit(<<byte>>, bit_number), do: <<clear_bit(byte, bit_number)>>

  @doc """
  Set the bit at the specified `bit_number` within the `byte` to the `bit`
  value.

  ## Example

      iex> set_bit(0, 1, 1)
      2

      iex> set_bit(<<0>>, 1, 1)
      <<2>>

      iex> set_bit(0, 1, true)
      2

      iex> set_bit(<<0>>, 1, true)
      <<2>>
  """
  @spec set_bit(byte | single_byte_binary, bit_number, bit) :: byte
  def set_bit(byte, bit_number, 1) when is_byte(byte) and is_bit_number(bit_number),
    do: set_bit(byte, bit_number)

  def set_bit(byte, bit_number, 0) when is_byte(byte) and is_bit_number(bit_number),
    do: clear_bit(byte, bit_number)

  def set_bit(byte, bit_number, true) when is_bit_number(bit_number),
    do: set_bit(byte, bit_number, 1)

  def set_bit(byte, bit_number, false) when is_bit_number(bit_number),
    do: set_bit(byte, bit_number, 0)

  def set_bit(<<byte>>, bit_number, value) when value in [0, 1],
    do: <<set_bit(byte, bit_number, value)>>

  @doc """
  Get the bit at the specified `bit_number` within `byte`.

  ## Example

      iex> get_bit(0x7f, 6)
      1

      iex> get_bit(<<0x7F>>, 6)
      1
  """
  @spec get_bit(byte | single_byte_binary, bit_number) :: bit
  def get_bit(byte, bit_number) when is_byte(byte) and is_bit_number(bit_number),
    do: byte >>> bit_number &&& 1

  def get_bit(<<byte>>, bit_number), do: get_bit(byte, bit_number)

  @doc """
  Return a bit out of a binary as a boolean value.

  ## Example

      iex> get_bool(0x7f, 6)
      true

      iex> get_bool(<<0x7F>>, 6)
      true
  """
  @spec get_bool(byte | single_byte_binary, bit_number) :: boolean
  def get_bool(byte, bit_number) when is_byte(byte) and is_bit_number(bit_number) do
    case(get_bit(byte, bit_number)) do
      1 -> true
      0 -> false
    end
  end

  def get_bool(<<byte>>, bit_number), do: get_bool(byte, bit_number)

  @doc """
  Returns the number of 1's in `byte`.

  ## Example

      iex> count_ones(0x7f)
      7

      iex> count_ones(<<0x7F>>)
      7
  """
  @spec count_ones(byte | single_byte_binary) :: non_neg_integer
  def count_ones(byte) when is_byte(byte) do
    0..7
    |> Enum.reduce(0, &(&2 + get_bit(byte, &1)))
  end

  def count_ones(<<byte>>), do: count_ones(byte)

  @doc """
  Returns the number of 0's in `byte`.

  ## Example

      iex> count_zeroes(0x7f)
      1

      iex> count_zeroes(<<0x7F>>)
      1
  """
  @spec count_zeroes(byte | single_byte_binary) :: non_neg_integer
  def count_zeroes(byte) when is_byte(byte) do
    0..7
    |> Enum.reduce(8, &(&2 - get_bit(byte, &1)))
  end

  def count_zeroes(<<byte>>), do: count_zeroes(byte)

  @doc """
  Find all the `1` bits in `byte` and return a list of `bit_number`s.

  ## Example

      iex> find_ones(0x0A)
      [1, 3]

      iex> find_ones(<<0x0A>>)
      [1, 3]
  """
  @spec find_ones(byte | single_byte_binary) :: [non_neg_integer]
  def find_ones(byte) when is_byte(byte) do
    0..7
    |> Enum.filter(&(get_bit(byte, &1) == 1))
  end

  def find_ones(<<byte>>), do: find_ones(byte)

  @doc """
  Find all the `0` bits in `byte` and return a list of `bit_number`s.

  ## Example

      iex> find_zeroes(0xFA)
      [0, 2]

      iex> find_zeroes(<<0xFA>>)
      [0, 2]
  """
  @spec find_zeroes(byte | single_byte_binary) :: [non_neg_integer]
  def find_zeroes(byte) when is_byte(byte) do
    0..7
    |> Enum.filter(&(get_bit(byte, &1) == 0))
  end

  def find_zeroes(<<byte>>), do: find_zeroes(byte)
end
