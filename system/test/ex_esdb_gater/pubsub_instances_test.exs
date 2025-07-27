defmodule ExESDBGater.PubSubInstancesTest do
  @moduledoc """
  Comprehensive tests for all PubSub instances to ensure proper isolation,
  message routing, and functional behavior across different event types.
  """
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

  setup do
    # Start supervisor with unique name
    sup_name = :"test_pubsub_#{System.unique_integer([:positive])}"
    {:ok, _sup} = ExESDBGater.PubSubSystem.start_link(name: sup_name)
    :ok
  end

  describe "PubSub instance availability" do
    test "all PubSub instances are properly started and named" do
      for instance <- @pubsub_instances do
        pid = Process.whereis(instance)
        assert is_pid(pid), "#{instance} should have a valid PID"
        assert Process.alive?(pid), "#{instance} should be alive"
      end
    end

    test "each PubSub instance has a unique process" do
      pids = Enum.map(@pubsub_instances, &Process.whereis/1)
      unique_pids = Enum.uniq(pids)
      
      assert length(pids) == length(unique_pids), 
             "All PubSub instances should have unique PIDs"
    end
  end

  describe "message isolation between instances" do
    test "messages sent to one instance don't leak to others" do
      test_pid = self()
      topic = "isolation_test"
      
      # Subscribe to the same topic on all instances
      for instance <- @pubsub_instances do
        :ok = PubSub.subscribe(instance, topic)
      end

      # Send a message to each instance and verify isolation
      for {instance, index} <- Enum.with_index(@pubsub_instances) do
        message = "message_#{index}_for_#{instance}"
        :ok = PubSub.broadcast(instance, topic, message)
        
        # Should receive exactly one message
        assert_receive ^message, 1000
        
        # Should not receive any other messages
        refute_receive _, 100
      end
    end

    test "different topics on same instance are isolated" do
      instance = :ex_esdb_events
      topic1 = "topic_1"
      topic2 = "topic_2"
      
      # Subscribe to different topics
      :ok = PubSub.subscribe(instance, topic1)
      :ok = PubSub.subscribe(instance, topic2)
      
      # Send message to topic1
      message1 = "message_for_topic_1"
      :ok = PubSub.broadcast(instance, topic1, message1)
      assert_receive ^message1
      
      # Send message to topic2
      message2 = "message_for_topic_2"
      :ok = PubSub.broadcast(instance, topic2, message2)
      assert_receive ^message2
      
      # No additional messages should be received
      refute_receive _, 100
    end
  end

  describe "concurrent message handling" do
    test "all instances can handle concurrent messages" do
      tasks = 
        for instance <- @pubsub_instances do
          Task.async(fn ->
            topic = "concurrent_test_#{instance}"
            message = "concurrent_message_#{instance}"
            
            # Subscribe and broadcast concurrently
            :ok = PubSub.subscribe(instance, topic)
            :ok = PubSub.broadcast(instance, topic, message)
            
            # Verify message received
            receive do
              ^message -> :ok
            after
              1000 -> {:error, :timeout}
            end
          end)
        end
      
      results = Task.await_many(tasks, 5000)
      
      # All tasks should complete successfully
      assert Enum.all?(results, &(&1 == :ok)), 
             "All concurrent operations should succeed"
    end

    test "high-volume message handling per instance" do
      instance = :ex_esdb_metrics  # Use metrics instance as it's likely to be high-volume
      topic = "high_volume_test"
      message_count = 100
      
      :ok = PubSub.subscribe(instance, topic)
      
      # Send many messages quickly
      for i <- 1..message_count do
        :ok = PubSub.broadcast(instance, topic, "message_#{i}")
      end
      
      # Receive all messages
      received_messages = 
        for _i <- 1..message_count do
          receive do
            msg -> msg
          after
            1000 -> :timeout
          end
        end
      
      # Verify we received all messages
      assert length(received_messages) == message_count
      assert :timeout not in received_messages
    end
  end

  describe "typical usage patterns" do
    test "health monitoring pattern" do
      health_topic = "subscription_health:test_store:test_subscription"
      
      :ok = PubSub.subscribe(:ex_esdb_health, health_topic)
      
      health_event = %{
        store_id: "test_store",
        subscription_name: "test_subscription",
        event_type: :registration_success,
        timestamp: System.system_time(:millisecond),
        metadata: %{proxy_pid: self()}
      }
      
      :ok = PubSub.broadcast(:ex_esdb_health, health_topic, {:subscription_health, health_event})
      
      assert_receive {:subscription_health, ^health_event}
    end

    test "metrics collection pattern" do
      metrics_topic = "subscription_metrics:test_store:test_subscription"
      
      :ok = PubSub.subscribe(:ex_esdb_metrics, metrics_topic)
      
      metrics_event = %{
        store_id: "test_store",
        subscription_name: "test_subscription",
        event_type: :registration_attempt,
        timestamp: System.system_time(:millisecond),
        metadata: %{result: :ok, source: :subscription_metrics}
      }
      
      :ok = PubSub.broadcast(:ex_esdb_metrics, metrics_topic, {:subscription_metrics, metrics_event})
      
      assert_receive {:subscription_metrics, ^metrics_event}
    end

    test "security event pattern" do
      security_topic = "security_events:authentication"
      
      :ok = PubSub.subscribe(:ex_esdb_security, security_topic)
      
      security_event = %{
        event_type: :authentication_failure,
        user_id: "test_user",
        ip_address: "192.168.1.1",
        timestamp: System.system_time(:millisecond),
        reason: :invalid_credentials
      }
      
      :ok = PubSub.broadcast(:ex_esdb_security, security_topic, {:security_event, security_event})
      
      assert_receive {:security_event, ^security_event}
    end

    test "audit trail pattern" do
      audit_topic = "audit_trail:user_actions"
      
      :ok = PubSub.subscribe(:ex_esdb_audit, audit_topic)
      
      audit_event = %{
        event_type: :user_action,
        user_id: "admin_user",
        action: :delete_subscription,
        resource: "subscription_123",
        timestamp: System.system_time(:millisecond),
        metadata: %{store_id: "test_store"}
      }
      
      :ok = PubSub.broadcast(:ex_esdb_audit, audit_topic, {:audit_event, audit_event})
      
      assert_receive {:audit_event, ^audit_event}
    end

    test "alert system pattern" do
      alert_topic = "system_alerts:critical"
      
      :ok = PubSub.subscribe(:ex_esdb_alerts, alert_topic)
      
      alert_event = %{
        event_type: :critical_alert,
        severity: :high,
        component: :subscription_system,
        message: "Circuit breaker opened for multiple subscriptions",
        timestamp: System.system_time(:millisecond),
        metadata: %{affected_subscriptions: 5}
      }
      
      :ok = PubSub.broadcast(:ex_esdb_alerts, alert_topic, {:critical_alert, alert_event})
      
      assert_receive {:critical_alert, ^alert_event}
    end

    test "lifecycle event pattern" do
      lifecycle_topic = "process_lifecycle:subscription_proxies"
      
      :ok = PubSub.subscribe(:ex_esdb_lifecycle, lifecycle_topic)
      
      lifecycle_event = %{
        event_type: :process_started,
        process_type: :subscription_proxy,
        pid: self(),
        timestamp: System.system_time(:millisecond),
        metadata: %{store_id: "test_store", subscription_name: "test_sub"}
      }
      
      :ok = PubSub.broadcast(:ex_esdb_lifecycle, lifecycle_topic, {:lifecycle_event, lifecycle_event})
      
      assert_receive {:lifecycle_event, ^lifecycle_event}
    end
  end

  describe "error handling and resilience" do
    test "PubSub instances handle subscriber crashes gracefully" do
      instance = :ex_esdb_system
      topic = "crash_test"
      
      # Start a process that will crash after subscribing
      crash_pid = spawn(fn ->
        :ok = PubSub.subscribe(instance, topic)
        receive do
          :crash -> raise "intentional crash"
          _ -> :ok
        end
      end)
      
      # Wait for subscription to be established
      Process.sleep(10)
      
      # Crash the subscriber
      send(crash_pid, :crash)
      Process.sleep(10)
      
      # PubSub should still work with a new subscriber
      :ok = PubSub.subscribe(instance, topic)
      :ok = PubSub.broadcast(instance, topic, "after_crash")
      
      assert_receive "after_crash"
    end

    test "invalid broadcasts don't crash PubSub instances" do
      instance = :ex_esdb_diagnostics
      topic = "error_test"
      
      :ok = PubSub.subscribe(instance, topic)
      
      # These should not crash the PubSub instance
      :ok = PubSub.broadcast(instance, topic, nil)
      :ok = PubSub.broadcast(instance, topic, %{})
      :ok = PubSub.broadcast(instance, topic, [])
      :ok = PubSub.broadcast(instance, topic, "normal_message")
      
      # Should receive all messages including the weird ones
      assert_receive nil
      assert_receive %{}
      assert_receive []
      assert_receive "normal_message"
      
      # PubSub instance should still be alive
      pid = Process.whereis(instance)
      assert Process.alive?(pid)
    end
  end

  describe "performance characteristics" do
    test "message delivery is reasonably fast" do
      instance = :ex_esdb_events
      topic = "performance_test"
      
      :ok = PubSub.subscribe(instance, topic)
      
      start_time = System.monotonic_time(:microsecond)
      :ok = PubSub.broadcast(instance, topic, "performance_message")
      
      receive do
        "performance_message" ->
          end_time = System.monotonic_time(:microsecond)
          delivery_time = end_time - start_time
          
          # Message should be delivered in less than 10ms (10,000 microseconds)
          assert delivery_time < 10_000, 
                 "Message delivery took #{delivery_time}μs, should be < 10,000μs"
      after
        1000 -> flunk("Message was not delivered within 1 second")
      end
    end

    test "multiple subscribers receive messages efficiently" do
      instance = :ex_esdb_logging
      topic = "multi_subscriber_test"
      subscriber_count = 10
      test_pid = self()
      
      # Start multiple subscriber processes
      subscribers = 
        for _i <- 1..subscriber_count do
          spawn(fn ->
            :ok = PubSub.subscribe(instance, topic)
            receive do
              "broadcast_message" -> send(test_pid, :received)
            end
          end)
        end
      
      # Wait for all subscriptions to be established
      Process.sleep(100)
      
      # Broadcast message
      start_time = System.monotonic_time(:microsecond)
      :ok = PubSub.broadcast(instance, topic, "broadcast_message")
      
      # Wait for all subscribers to receive the message
      for _i <- 1..subscriber_count do
        receive do
          :received -> :ok
        after
          2000 -> flunk("Did not receive all messages from subscribers")
        end
      end
      
      end_time = System.monotonic_time(:microsecond)
      total_time = end_time - start_time
      
      # Should deliver to all subscribers in reasonable time
      assert total_time < 500_000, 
             "Broadcasting to #{subscriber_count} subscribers took #{total_time}μs"
    end
  end
end
