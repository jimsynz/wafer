defmodule Wafer.DLL.Rx do
  defstruct [:buffer, :state]
  alias __MODULE__

  @moduledoc """
  Bytewise reception buffer for our data link layer.
  """

  defguardp is_byte(byte) when is_integer(byte) and byte >= 0 and byte <= 255

  @byte_start 0x7D
  @byte_end 0x7E
  @byte_esc 0x7F

  @type t :: %Rx{buffer: binary, state: any}

  @doc """
  Initialize a new empty buffer reading for receiving.
  """
  def init, do: %Rx{buffer: <<>>, state: :idle}

  @doc """
  Receive a byte into the buffer.
  """
  @spec rx(t, byte) :: t
  def rx(%Rx{state: state}, @byte_start) when state != :escaping,
    do: %Rx{buffer: <<>>, state: :receiving}

  def rx(%Rx{state: :idle} = rx, _byte), do: rx
  def rx(%Rx{state: :receiving} = rx, @byte_esc), do: %{rx | state: :escaping}

  def rx(%Rx{state: :receiving, buffer: <<crc::integer-size(32), buffer::binary>>}, @byte_end) do
    if :erlang.crc32(buffer) == crc do
      %Rx{buffer: :erlang.binary_to_term(buffer), state: :complete}
    else
      %Rx{buffer: buffer, state: {:error, :crc_mismatch}}
    end
  end

  def rx(%Rx{state: :receiving} = rx, @byte_end), do: %{rx | state: {:error, :too_short}}

  def rx(%Rx{state: :escaping, buffer: buffer}, byte) when is_byte(byte),
    do: %Rx{state: :receiving, buffer: <<buffer::binary, byte::integer-size(8)>>}

  def rx(%Rx{state: :receiving, buffer: buffer}, byte) when is_byte(byte),
    do: %Rx{state: :receiving, buffer: <<buffer::binary, byte::integer-size(8)>>}

  def rx(%Rx{state: :complete} = rx, _byte), do: rx

  @doc """
  Has the reception completed successfully?
  """
  @spec complete?(t) :: boolean
  def complete?(%Rx{state: :complete}), do: true
  def complete?(%Rx{}), do: false

  @doc """
  Was there an error during reception?
  """
  @spec error?(t) :: boolean
  def error?(%Rx{state: {:error, _}}), do: true
  def error?(%Rx{}), do: false

  @doc """
  Attempt to retrieve the received value from the buffer.
  """
  @spec value(t) :: {:ok, any} | {:error, any}
  def value(%Rx{state: :complete, buffer: buffer}), do: {:ok, buffer}
  def value(%Rx{state: {:error, reason}}), do: {:error, reason}
  def value(%Rx{}), do: {:error, :incomplete}
end
