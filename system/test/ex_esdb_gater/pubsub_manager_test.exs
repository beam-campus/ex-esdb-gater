defmodule BCGater.PubSubManagerTest do
  use ExUnit.Case, async: false

  alias BCGater.PubSubManager

  setup do
    # Clean up any running PubSub instances
    for name <- [:test_pubsub_new, :test_pubsub_running, :test_pubsub_supervised] do
      if pid = Process.whereis(name) do
        Process.exit(pid, :kill)
        Process.sleep(10)
      end
    end

    :ok
  end

  test "returns nil for nil input" do
    assert PubSubManager.maybe_child_spec(nil) == nil
  end

  test "returns child spec for non-running PubSub" do
    name = :test_pubsub_new
    spec = PubSubManager.maybe_child_spec(name)

    assert is_tuple(spec)
    assert elem(spec, 0) == Phoenix.PubSub
    config = elem(spec, 1)
    assert Keyword.get(config, :name) == name
    assert Keyword.get(config, :adapter) == Phoenix.PubSub.PG2
    assert Keyword.get(config, :pool_size) == 1
  end

  test "returns nil for already running PubSub" do
    name = :test_pubsub_running

    # Start PubSub directly
    {:ok, _pid} = Phoenix.PubSub.Supervisor.start_link(name: name, adapter: Phoenix.PubSub.PG2)

    # Should return nil since already running
    assert PubSubManager.maybe_child_spec(name) == nil
  end

  test "can be used in supervision tree" do
    name = :test_pubsub_supervised
    spec = PubSubManager.maybe_child_spec(name)

    # Start a supervisor with our PubSub
    {:ok, sup_pid} = Supervisor.start_link([spec], strategy: :one_for_one)

    # Verify PubSub is running
    assert Process.whereis(name) != nil

    # Cleanup
    Process.exit(sup_pid, :normal)
  end
end
