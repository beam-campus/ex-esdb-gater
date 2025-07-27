defmodule ExESDBGater.PubSubSystemTest do
  use ExUnit.Case, async: false

  alias Phoenix.PubSub

  @pubsub_instances [
    :ex_esdb_events,      # Core event data
    :ex_esdb_system,      # General system events
    :ex_esdb_logging,     # Log aggregation
    :ex_esdb_health,      # Health monitoring
    :ex_esdb_metrics,     # Performance metrics
    :ex_esdb_security,    # Security events
    :ex_esdb_audit,       # Audit trail
    :ex_esdb_alerts,      # Critical alerts
    :ex_esdb_diagnostics, # Deep diagnostic information
    :ex_esdb_lifecycle    # Process lifecycle events
  ]

  test "multiple PubSubSystem supervisors share PubSub instances" do
    # Start first supervisor
    assert {:ok, sup1} = ExESDBGater.PubSubSystem.start_link(name: :pubsub_system_1)

    # Record initial PIDs
    initial_pids = for name <- @pubsub_instances, do: {name, Process.whereis(name)}

    # Start second supervisor - should reuse existing PubSub instances
    assert {:ok, sup2} = ExESDBGater.PubSubSystem.start_link(name: :pubsub_system_2)

    # Get PIDs after second supervisor
    current_pids = for name <- @pubsub_instances, do: {name, Process.whereis(name)}

    # PIDs should be identical - instances are shared
    assert initial_pids == current_pids

    # Verify PubSub works through both supervisors
    topic = "test_topic"
    message = "test message"

    # Subscribe through first supervisor's PubSub
    :ok = PubSub.subscribe(:ex_esdb_events, topic)

    # Broadcast through second supervisor's PubSub
    :ok = PubSub.broadcast(:ex_esdb_events, topic, message)

    # Should receive message
    assert_receive ^message

    # Clean up
    Supervisor.stop(sup1)
    Supervisor.stop(sup2)

    # PubSub instances should still be running
    for {name, pid} <- current_pids do
      assert Process.alive?(pid), "PubSub #{name} should still be alive"
      assert pid == Process.whereis(name), "PubSub #{name} should have same PID"
    end
  end
end
