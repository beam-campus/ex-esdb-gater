defmodule ExESDBGater.TopicsTest do
  use ExUnit.Case, async: true
  
  alias ExESDBGater.Topics

  describe "store-specific topics" do
    test "generates correct health topic" do
      assert Topics.store_health(:vehicle_store) == "vehicle_store:health"
      assert Topics.store_health(:reckon_store) == "reckon_store:health"
    end

    test "generates correct lifecycle topic" do
      assert Topics.store_lifecycle(:vehicle_store) == "vehicle_store:lifecycle"
    end

    test "generates correct streams topic" do
      assert Topics.store_streams(:vehicle_store) == "vehicle_store:streams"
    end

    test "generates correct replicas topic" do  
      assert Topics.store_replicas(:vehicle_store) == "vehicle_store:replicas"
    end

    test "generates correct events topic" do
      assert Topics.store_events(:vehicle_store) == "vehicle_store:events"
    end

    test "generates correct alerts topic" do
      assert Topics.store_alerts(:vehicle_store) == "vehicle_store:alerts"
    end

    test "generates correct performance topic" do
      assert Topics.store_performance(:vehicle_store) == "vehicle_store:performance"
    end

    test "generates correct subscriptions topic" do
      assert Topics.store_subscriptions(:vehicle_store) == "vehicle_store:subscriptions"
    end
  end

  describe "cluster-level topics" do
    test "generates correct cluster health topic" do
      assert Topics.cluster_health() == "cluster:health"
    end

    test "generates correct cluster topology topic" do
      assert Topics.cluster_topology() == "cluster:topology"
    end

    test "generates correct cluster leader topic" do
      assert Topics.cluster_leader() == "cluster:leader"
    end

    test "generates correct cluster discovery topic" do
      assert Topics.cluster_discovery() == "cluster:discovery"
    end

    test "generates correct cluster alerts topic" do
      assert Topics.cluster_alerts() == "cluster:alerts"
    end

    test "generates correct cluster performance topic" do
      assert Topics.cluster_performance() == "cluster:performance"
    end
  end

  describe "generic topic builders" do
    test "store_topic/2 generates custom store topics" do
      assert Topics.store_topic(:my_store, :custom) == "my_store:custom"
      assert Topics.store_topic(:test_store, :special_events) == "test_store:special_events"
    end

    test "cluster_topic/1 generates custom cluster topics" do
      assert Topics.cluster_topic(:maintenance) == "cluster:maintenance"
      assert Topics.cluster_topic(:diagnostics) == "cluster:diagnostics"
    end
  end

  describe "topic validation" do
    test "valid_topic?/1 validates correct patterns" do
      assert Topics.valid_topic?("vehicle_store:health") == true
      assert Topics.valid_topic?("cluster:topology") == true
      assert Topics.valid_topic?("any_store:any_topic") == true
    end

    test "valid_topic?/1 rejects invalid patterns" do
      assert Topics.valid_topic?("invalid") == false
      assert Topics.valid_topic?("too:many:colons") == true  # Still valid with 2+ parts
      assert Topics.valid_topic?("") == false
    end
  end

  describe "topic parsing" do
    test "parse_topic/1 parses store topics correctly" do
      assert Topics.parse_topic("vehicle_store:health") == {:store, :vehicle_store, :health}
      assert Topics.parse_topic("my_store:custom_event") == {:store, :my_store, :custom_event}
    end

    test "parse_topic/1 parses cluster topics correctly" do
      assert Topics.parse_topic("cluster:topology") == {:cluster, nil, :topology}
      assert Topics.parse_topic("cluster:health") == {:cluster, nil, :health}
    end

    test "parse_topic/1 handles invalid topics" do
      assert Topics.parse_topic("invalid") == {:error, :invalid_format}
      assert Topics.parse_topic("") == {:error, :invalid_format}
    end
  end

  describe "store ID validation" do
    test "valid_store_id?/1 validates proper store IDs" do
      assert Topics.valid_store_id?(:vehicle_store) == true
      assert Topics.valid_store_id?(:my_store) == true
    end

    test "valid_store_id?/1 rejects invalid store IDs" do
      assert Topics.valid_store_id?(nil) == false
      assert Topics.valid_store_id?(:"") == false
      assert Topics.valid_store_id?("string") == false
      assert Topics.valid_store_id?(123) == false
    end
  end

  describe "topic collections" do
    test "store_sub_topics/0 returns all store sub-topics" do
      sub_topics = Topics.store_sub_topics()
      
      assert :health in sub_topics
      assert :lifecycle in sub_topics
      assert :streams in sub_topics
      assert :replicas in sub_topics
      assert :events in sub_topics
      assert :alerts in sub_topics
      assert :performance in sub_topics
      assert :subscriptions in sub_topics
    end

    test "cluster_sub_topics/0 returns all cluster sub-topics" do
      sub_topics = Topics.cluster_sub_topics()
      
      assert :health in sub_topics
      assert :topology in sub_topics
      assert :leader in sub_topics
      assert :discovery in sub_topics
      assert :alerts in sub_topics
      assert :performance in sub_topics
    end

    test "all_store_topics/1 generates all standard topics for a store" do
      topics = Topics.all_store_topics(:test_store)
      
      assert "test_store:health" in topics
      assert "test_store:lifecycle" in topics
      assert "test_store:streams" in topics
      assert "test_store:replicas" in topics
      assert "test_store:events" in topics
      assert "test_store:alerts" in topics
      assert "test_store:performance" in topics
      assert "test_store:subscriptions" in topics
    end

    test "all_cluster_topics/0 generates all standard cluster topics" do
      topics = Topics.all_cluster_topics()
      
      assert "cluster:health" in topics
      assert "cluster:topology" in topics
      assert "cluster:leader" in topics
      assert "cluster:discovery" in topics
      assert "cluster:alerts" in topics
      assert "cluster:performance" in topics
    end
  end
end
