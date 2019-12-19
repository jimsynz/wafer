defmodule ChipHopTest do
  use ExUnit.Case
  doctest ChipHop

  test "greets the world" do
    assert ChipHop.hello() == :world
  end
end
