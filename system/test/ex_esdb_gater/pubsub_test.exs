defmodule ExESDBGater.PubSubTest do
  use ExUnit.Case, async: false

  alias Phoenix.PubSub

  @pubsub_instances [:ex_esdb_events, :ex_esdb_system, :ex_esdb_logging]

  setup do
    # Start supervisor with unique name
    sup_name = :'test_pubsub_#{System.unique_integer([:positive])}'
    {:ok, _sup} = ExESDBGater.PubSubSystem.start_link(name: sup_name)
    :ok
  end

  test "all PubSub instances are running" do
    for name <- @pubsub_instances do
      pid = Process.whereis(name)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end

  test "can subscribe and receive messages on each PubSub instance" do
    _test_pid = self()

    for name <- @pubsub_instances do
      topic = "test_topic_#{name}"
      message = "test_message_#{name}"

      # Subscribe to topic
      :ok = PubSub.subscribe(name, topic)

      # Broadcast a message
      :ok = PubSub.broadcast(name, topic, message)

      # Verify message received
      assert_receive ^message
    end
  end

  test "starting multiple PubSubSystems works" do
    # Start additional supervisors with unique names
    sup1_name = :'test_pubsub_1_#{System.unique_integer([:positive])}'
    sup2_name = :'test_pubsub_2_#{System.unique_integer([:positive])}'

    {:ok, sup1} = ExESDBGater.PubSubSystem.start_link(name: sup1_name)
    {:ok, sup2} = ExESDBGater.PubSubSystem.start_link(name: sup2_name)

    # Verify PubSub instances are still working
    for name <- @pubsub_instances do
      topic = "test_topic_#{name}"
      message = "test_message_#{name}"

      # Subscribe and publish should work without errors
      :ok = PubSub.subscribe(name, topic)
      :ok = PubSub.broadcast(name, topic, message)
      assert_receive ^message
    end

    # Clean up
    Supervisor.stop(sup1)
    Supervisor.stop(sup2)
  end

  test "PubSub instances persist across supervisor restarts" do
    # Get initial PIDs
    initial_pids = for name <- @pubsub_instances, do: {name, Process.whereis(name)}

    # Start a new supervisor with unique name
    sup_name = :'test_pubsub_3_#{System.unique_integer([:positive])}'
    {:ok, sup} = ExESDBGater.PubSubSystem.start_link(name: sup_name)

    # Get new PIDs
    new_pids = for name <- @pubsub_instances, do: {name, Process.whereis(name)}

    # Verify instances are running and can handle messages
    for {name, pid} <- new_pids do
      assert is_pid(pid)
      assert Process.alive?(pid)

      # Try sending a message
      topic = "test_topic_after_restart_#{name}"
      message = "test_message_after_restart_#{name}"
      :ok = PubSub.subscribe(name, topic)
      :ok = PubSub.broadcast(name, topic, message)
      assert_receive ^message
    end

    # The PubSub instances should be reused (same PIDs)
    assert initial_pids == new_pids

    # Clean up
    Supervisor.stop(sup)
  end

  test "each PubSub instance is isolated" do
    _test_pid = self()

    # Subscribe to same topic name on each instance
    topic = "shared_topic"
    for name <- @pubsub_instances do
      :ok = PubSub.subscribe(name, topic)
    end

    # Send message to first instance
    message = "message_for_events"
    :ok = PubSub.broadcast(:ex_esdb_events, topic, message)

    # Should only receive one message
    assert_receive ^message
    refute_receive ^message, 100

    # Verify same for other instances
    message2 = "message_for_system"
    :ok = PubSub.broadcast(:ex_esdb_system, topic, message2)
    assert_receive ^message2
    refute_receive ^message2, 100

    message3 = "message_for_logging"
    :ok = PubSub.broadcast(:ex_esdb_logging, topic, message3)
    assert_receive ^message3
    refute_receive ^message3, 100
  end
end
