defmodule Wafer.DLL.Tx do
  defstruct [:buffer, :state]
  alias __MODULE__

  @moduledoc """
  A bytewise transmission buffer for our data link layer.
  """

  @byte_start 0x7D
  @byte_end 0x7E
  @byte_esc 0x7F

  @type t :: %Tx{buffer: binary, state: any}

  @doc """
  Initialize a new transmission buffer from a term.
  """
  @spec init(any) :: t
  def init(term) do
    data = :erlang.term_to_binary(term)
    crc = :erlang.crc32(data)
    %Tx{buffer: <<crc::integer-size(32), data::binary>>, state: :idle}
  end

  @doc """
  Get the next byte to transmit.
  """
  @spec tx(t) :: {byte, t} | :done
  def tx(%Tx{state: :idle} = tx), do: {@byte_start, %{tx | state: :transmitting}}

  def tx(%Tx{state: :transmitting, buffer: <<@byte_start::integer-size(8), _::binary>>} = rx),
    do: {@byte_esc, %{rx | state: :escaping}}

  def tx(%Tx{state: :transmitting, buffer: <<@byte_end::integer-size(8), _::binary>>} = rx),
    do: {@byte_esc, %{rx | state: :escaping}}

  def tx(%Tx{state: :transmitting, buffer: <<@byte_esc::integer-size(8), _::binary>>} = rx),
    do: {@byte_esc, %{rx | state: :escaping}}

  def tx(%Tx{state: :transmitting, buffer: <<byte::integer-size(8), buffer::binary>>} = rx),
    do: {byte, %{rx | state: :transmitting, buffer: buffer}}

  def tx(%Tx{state: :escaping, buffer: <<byte::integer-size(8), buffer::binary>>} = rx),
    do: {byte, %{rx | state: :escaping, buffer: buffer}}

  def tx(%Tx{buffer: <<>>, state: :transmitting} = rx), do: {@byte_end, %{rx | state: :complete}}
  def tx(%Tx{state: :complete}), do: :done

  def complete?(%Tx{state: :complete}), do: true
  def complete?(%Tx{}), do: false
end
