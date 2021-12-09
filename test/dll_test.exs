defmodule WaferDLLTest do
  use ExUnit.Case, async: true
  alias Wafer.DLL.{Rx, Tx}

  test "synchronised transmission" do
    value = {:marty, "McFly"}

    tx = Tx.init(value)
    rx = Rx.init()

    {tx, rx} = transmit(tx, rx)

    assert Tx.complete?(tx)
    assert Rx.complete?(rx)
    assert {:ok, ^value} = Rx.value(rx)
  end

  def transmit(%Tx{} = tx, %Rx{} = rx) do
    case Tx.tx(tx) do
      {:done, tx} ->
        {tx, rx}

      {byte, tx} ->
        rx = Rx.rx(rx, byte)
        transmit(tx, rx)
    end
  end
end
