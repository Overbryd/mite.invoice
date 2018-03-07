defmodule MiteTest do
  use ExUnit.Case
  doctest Mite

  test "greets the world" do
    assert Mite.hello() == :world
  end
end
