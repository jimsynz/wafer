defmodule WaferDLLRxTest do
  use ExUnit.Case, async: true
  alias Wafer.DLL.Rx

  test "ignores bytes until it receives the start byte" do
    rx = Rx.init()

    rx = Rx.rx(rx, 0)
    assert rx.state == :idle

    rx = Rx.rx(rx, 1)
    assert rx.state == :idle

    rx = Rx.rx(rx, 2)
    assert rx.state == :idle

    rx = Rx.rx(rx, 0x7D)
    assert rx.state == :receiving
  end

  test "resynchronises on start byte" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0)

    assert rx.buffer == <<0>>

    rx = Rx.rx(rx, 0x7D)
    assert rx.buffer == <<>>
  end

  test "handles escaped bytes" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0x7F)
      |> Rx.rx(0)

    assert rx.buffer == <<0>>
  end

  test "handles double escapes" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0x7F)
      |> Rx.rx(0x7F)

    assert rx.buffer == <<0x7F>>
  end

  test "handles escaped start bytes" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0x7F)
      |> Rx.rx(0x7D)

    assert rx.buffer == <<0x7D>>
  end

  test "handles escaped end bytes" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0x7F)
      |> Rx.rx(0x7E)

    assert rx.buffer == <<0x7E>>
  end

  test "receives bytes until the end" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(167)
      |> Rx.rx(142)
      |> Rx.rx(61)
      |> Rx.rx(132)
      |> Rx.rx(131)
      |> Rx.rx(100)
      |> Rx.rx(0)
      |> Rx.rx(1)
      |> Rx.rx(97)
      |> Rx.rx(126)

    assert rx.state == :complete
    assert rx.buffer == :a
  end

  test "results in an error when the payload is too short" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(0)
      |> Rx.rx(0x7E)

    assert rx.state == {:error, :too_short}
  end

  test "ignores non-start bytes when the payload is complete" do
    rx =
      Rx.init()
      |> Rx.rx(0x7D)
      |> Rx.rx(167)
      |> Rx.rx(142)
      |> Rx.rx(61)
      |> Rx.rx(132)
      |> Rx.rx(131)
      |> Rx.rx(100)
      |> Rx.rx(0)
      |> Rx.rx(1)
      |> Rx.rx(97)
      |> Rx.rx(126)
      |> Rx.rx(0)

    assert rx.state == :complete
    assert rx.buffer == :a
  end
end
