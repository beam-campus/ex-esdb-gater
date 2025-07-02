defmodule GatewayApiTest do
  use ExUnit.Case
  doctest GatewayApi

  test "greets the world" do
    assert GatewayApi.hello() == :world
  end
end
