defmodule WaferDllTxTest do
  use ExUnit.Case, async: true
  alias Wafer.DLL.Tx

  test "it sends the start byte first" do
    bytes = collect(:test)
    byte = List.first(bytes)
    assert byte == 0x7D
  end

  test "it sends the end byte last" do
    bytes = collect(:test)
    byte = List.last(bytes)
    assert byte == 0x7E
  end

  test "it includes a valid CRC" do
    crc0 = :erlang.crc32(:erlang.term_to_binary(:test))

    <<_start::integer-size(8), crc1::integer-size(32), _::binary>> =
      :binary.list_to_bin(collect(:test))

    assert crc0 == crc1
  end

  defp collect(term), do: collect(Tx.init(term), [])

  defp collect(tx, bytes) do
    case Tx.tx(tx) do
      {byte, tx} -> collect(tx, [byte | bytes])
      :done -> Enum.reverse(bytes)
    end
  end
end
