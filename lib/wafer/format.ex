defmodule Wafer.Format do
  use Bitwise

  @moduledoc """
  Handy functions for formatting bytes, especially for debugging.
  """

  @doc """
  Convert the provided value into it's 0-padded byte-oriented string
  representation.

  ## Examples

      iex> to_hex(0x1234)
      "0x1234"

      iex> to_hex(<<0xF0, 0x0F>>)
      "0xF00F"
  """
  @spec to_hex(integer | binary) :: String.t()
  def to_hex(value) when is_integer(value) do
    value
    |> :binary.encode_unsigned()
    |> to_hex()
  end

  def to_hex(value) when is_binary(value) do
    bits =
      value
      |> :binary.bin_to_list()
      |> Stream.map(&Integer.to_string(&1, 16))
      |> Stream.map(&String.pad_leading(&1, 2, "0"))
      |> Enum.join("")

    "0x" <> bits
  end

  @doc """
  Convert the provided value into it's 0-padded byte-oriented string
  representation.

  ## Examples

      iex> to_bin(0x1234)
      "0b00010010_00110100"

      iex> to_bin(<<0xF0, 0x0F>>)
      "0b11110000_00001111"
  """
  @spec to_bin(integer | binary) :: String.t()
  def to_bin(value) when is_integer(value) do
    value
    |> :binary.encode_unsigned()
    |> to_bin()
  end

  def to_bin(value) when is_binary(value) do
    bits =
      value
      |> :binary.bin_to_list()
      |> Stream.map(&Integer.to_string(&1, 2))
      |> Stream.map(&String.pad_leading(&1, 8, "0"))
      |> Enum.join("_")

    "0b" <> bits
  end
end
