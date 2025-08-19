defmodule ExESDBGater.Messages.HealthMessagesTest do
  use ExUnit.Case, async: true
  
  alias ExESDBGater.Messages.HealthMessages
  alias ExESDBGater.Messages.HealthMessages.{NodeHealth, ClusterHealth, ComponentHealth, HealthCheck}

  describe "payload struct creation" do
    test "node_health/3 creates valid NodeHealth struct with defaults" do
      payload = HealthMessages.node_health(:test_node, :healthy)
      
      assert %NodeHealth{} = payload
      assert payload.node == :test_node
      assert payload.status == :healthy
      assert payload.checks == %{}
      assert payload.load_avg == nil
      assert payload.memory_usage == nil
      assert payload.disk_usage == nil
      assert %DateTime{} = payload.timestamp
    end

    test "node_health/3 creates valid NodeHealth struct with options" do
      opts = [
        checks: %{disk: :ok, memory: :ok},
        load_avg: 0.5,
        memory_usage: 75.0,
        disk_usage: 45.0
      ]
      
      payload = HealthMessages.node_health(:test_node, :degraded, opts)
      
      assert payload.node == :test_node
      assert payload.status == :degraded
      assert payload.checks == %{disk: :ok, memory: :ok}
      assert payload.load_avg == 0.5
      assert payload.memory_usage == 75.0
      assert payload.disk_usage == 45.0
    end

    test "cluster_health/3 creates valid ClusterHealth struct" do
      payload = HealthMessages.cluster_health(:healthy, 3, 5)
      
      assert %ClusterHealth{} = payload
      assert payload.status == :healthy
      assert payload.healthy_nodes == 3
      assert payload.total_nodes == 5
      assert payload.degraded_nodes == []
      assert payload.unhealthy_nodes == []
      assert payload.quorum_status == :available
      assert %DateTime{} = payload.timestamp
    end

    test "component_health/4 creates valid ComponentHealth struct" do
      payload = HealthMessages.component_health(:database, :node1, :degraded)
      
      assert %ComponentHealth{} = payload
      assert payload.component == :database
      assert payload.node == :node1
      assert payload.status == :degraded
      assert payload.details == %{}
      assert payload.last_check == nil
      assert %DateTime{} = payload.timestamp
    end

    test "health_check/4 creates valid HealthCheck struct" do
      payload = HealthMessages.health_check(:disk_space, :node1, :pass)
      
      assert %HealthCheck{} = payload
      assert payload.check_name == :disk_space
      assert payload.node == :node1
      assert payload.result == :pass
      assert payload.duration_ms == nil
      assert payload.details == %{}
      assert payload.error == nil
      assert %DateTime{} = payload.timestamp
    end
  end

  describe "topic helper functions" do
    test "store_health_topic/1 generates correct store health topics" do
      assert HealthMessages.store_health_topic(:vehicle_store) == "vehicle_store:health"
      assert HealthMessages.store_health_topic(:reckon_store) == "reckon_store:health"
      assert HealthMessages.store_health_topic(:test_store) == "test_store:health"
    end

    test "cluster_health_topic/0 generates correct cluster health topic" do
      assert HealthMessages.cluster_health_topic() == "cluster:health"
    end
  end

  describe "broadcast_store_health/2 pattern matching" do
    # Note: These tests focus on function dispatch and ensure correct pattern matching works
    
    test "accepts NodeHealth payload with valid store_id" do
      node_health = HealthMessages.node_health(:test_node, :healthy)
      
      # This should work without error - the function clause should match
      # The actual broadcast will fail but that's expected without PubSub running
      result = HealthMessages.broadcast_store_health(:test_store, node_health)
      # We expect either :ok or an error tuple/exception - the important thing is no FunctionClauseError
      assert result == :ok or match?({:error, _}, result)
    end

    test "accepts ComponentHealth payload with valid store_id" do
      component_health = HealthMessages.component_health(:database, :node1, :degraded)
      
      result = HealthMessages.broadcast_store_health(:test_store, component_health)
      assert result == :ok or match?({:error, _}, result)
    end

    test "accepts HealthCheck payload with valid store_id" do
      health_check = HealthMessages.health_check(:disk_space, :node1, :pass)
      
      result = HealthMessages.broadcast_store_health(:test_store, health_check)
      assert result == :ok or match?({:error, _}, result)
    end

    test "rejects non-atom store_id" do
      node_health = HealthMessages.node_health(:test_node, :healthy)
      
      # Should raise FunctionClauseError for invalid store_id
      assert_raise FunctionClauseError, fn ->
        HealthMessages.broadcast_store_health("invalid_store_id", node_health)
      end
    end

    test "rejects unsupported payload types" do
      # Should raise FunctionClauseError for unsupported payload
      assert_raise FunctionClauseError, fn ->
        HealthMessages.broadcast_store_health(:test_store, %{unsupported: :payload})
      end
    end
  end

  describe "broadcast_cluster_health_update/1 pattern matching" do
    test "accepts ClusterHealth payload" do
      cluster_health = HealthMessages.cluster_health(:healthy, 3, 5)
      
      result = HealthMessages.broadcast_cluster_health_update(cluster_health)
      assert result == :ok or match?({:error, _}, result)
    end

    test "accepts NodeHealth payload" do
      node_health = HealthMessages.node_health(:test_node, :healthy)
      
      result = HealthMessages.broadcast_cluster_health_update(node_health)
      assert result == :ok or match?({:error, _}, result)
    end

    test "rejects unsupported payload types" do
      component_health = HealthMessages.component_health(:database, :node1, :degraded)
      
      # Should raise FunctionClauseError for unsupported payload type
      assert_raise FunctionClauseError, fn ->
        HealthMessages.broadcast_cluster_health_update(component_health)
      end
    end

    test "rejects invalid payload" do
      assert_raise FunctionClauseError, fn ->
        HealthMessages.broadcast_cluster_health_update(%{invalid: :payload})
      end
    end
  end

  describe "secure message validation" do
    setup do
      # Mock messages for testing validation logic
      original_message = {:node_health_updated, HealthMessages.node_health(:test, :healthy)}
      
      %{
        unsecured_message: {:unsecured_message, original_message},
        original_message: original_message
      }
    end

    test "validate_secure_message/1 handles unsecured message format when no secret configured", %{unsecured_message: msg} do
      # When no secret is configured, unsecured messages should be rejected if a secret is available,
      # or accepted with a warning if no secret is configured
      result = HealthMessages.validate_secure_message(msg)
      
      # The result depends on whether a secret is configured in the test environment
      assert result in [{:error, :unsecured_message_rejected}, {:ok, {:node_health_updated, %NodeHealth{}}}]
    end

    test "validate_secure_message/1 rejects invalid format" do
      assert {:error, :invalid_format} = HealthMessages.validate_secure_message({:invalid, :format})
      assert {:error, :invalid_format} = HealthMessages.validate_secure_message("string")
      assert {:error, :invalid_format} = HealthMessages.validate_secure_message(%{map: :value})
    end
    
    test "validate_secure_message/1 handles secure message format" do
      # Test with a properly formed secure message tuple
      # Use a 32-byte signature to match the expected HMAC-SHA256 output length
      original_message = {:node_health_updated, HealthMessages.node_health(:test, :healthy)}
      fake_signature = :crypto.strong_rand_bytes(32)
      secure_msg = {:secure_message, fake_signature, original_message}
      
      # This will fail due to signature validation, but should not crash
      result = HealthMessages.validate_secure_message(secure_msg)
      assert {:error, _reason} = result
    end
  end

  describe "payload struct validation" do
    test "NodeHealth struct has all required fields" do
      payload = %NodeHealth{
        node: :test_node,
        status: :healthy,
        checks: %{},
        load_avg: nil,
        memory_usage: nil,
        disk_usage: nil,
        timestamp: DateTime.utc_now()
      }
      
      assert payload.node == :test_node
      assert payload.status == :healthy
      refute payload.load_avg
      refute payload.memory_usage
      refute payload.disk_usage
    end

    test "ClusterHealth struct has all required fields" do
      payload = %ClusterHealth{
        status: :degraded,
        healthy_nodes: 2,
        total_nodes: 5,
        degraded_nodes: [:node3],
        unhealthy_nodes: [:node4, :node5],
        quorum_status: :lost,
        timestamp: DateTime.utc_now()
      }
      
      assert payload.status == :degraded
      assert payload.healthy_nodes == 2
      assert payload.total_nodes == 5
      assert payload.degraded_nodes == [:node3]
      assert payload.unhealthy_nodes == [:node4, :node5]
      assert payload.quorum_status == :lost
    end

    test "ComponentHealth struct has all required fields" do
      last_check = DateTime.utc_now()
      
      payload = %ComponentHealth{
        component: :eventstoredb,
        node: :node1,
        status: :unhealthy,
        details: %{error: "Connection refused"},
        last_check: last_check,
        timestamp: DateTime.utc_now()
      }
      
      assert payload.component == :eventstoredb
      assert payload.node == :node1
      assert payload.status == :unhealthy
      assert payload.details == %{error: "Connection refused"}
      assert payload.last_check == last_check
    end

    test "HealthCheck struct has all required fields" do
      payload = %HealthCheck{
        check_name: :database_connection,
        node: :node2,
        result: :fail,
        duration_ms: 5000,
        details: %{retries: 3},
        error: "Connection timeout",
        timestamp: DateTime.utc_now()
      }
      
      assert payload.check_name == :database_connection
      assert payload.node == :node2
      assert payload.result == :fail
      assert payload.duration_ms == 5000
      assert payload.details == %{retries: 3}
      assert payload.error == "Connection timeout"
    end
  end

  describe "timestamp handling" do
    test "all payload creation functions set current timestamp" do
      before = DateTime.utc_now()
      
      node_health = HealthMessages.node_health(:test, :healthy)
      cluster_health = HealthMessages.cluster_health(:healthy, 1, 1)
      component_health = HealthMessages.component_health(:test, :node, :healthy)
      health_check = HealthMessages.health_check(:test, :node, :pass)
      
      after_time = DateTime.utc_now()
      
      # All timestamps should be between before and after
      assert DateTime.compare(node_health.timestamp, before) in [:gt, :eq]
      assert DateTime.compare(node_health.timestamp, after_time) in [:lt, :eq]
      
      assert DateTime.compare(cluster_health.timestamp, before) in [:gt, :eq]
      assert DateTime.compare(cluster_health.timestamp, after_time) in [:lt, :eq]
      
      assert DateTime.compare(component_health.timestamp, before) in [:gt, :eq]
      assert DateTime.compare(component_health.timestamp, after_time) in [:lt, :eq]
      
      assert DateTime.compare(health_check.timestamp, before) in [:gt, :eq]
      assert DateTime.compare(health_check.timestamp, after_time) in [:lt, :eq]
    end
  end
end
