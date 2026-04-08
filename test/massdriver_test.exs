defmodule MassdriverTest do
  use ExUnit.Case
  doctest Massdriver

  test "greets the world" do
    assert Massdriver.hello() == :world
  end
end
