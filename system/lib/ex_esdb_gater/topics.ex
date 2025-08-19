defmodule ExESDBGater.Topics do
  @moduledoc """
  Topic naming utilities for consistent PubSub topic patterns across the ExESDB ecosystem.
  
  This module provides helper functions to generate topic names following the standard pattern:
  "{store_id}:{sub_topic}" for store-specific events and "cluster:{sub_topic}" for cluster-wide events.
  
  ## Examples
  
      # Store-specific topics
      Topics.store_health(:vehicle_store) 
      #=> "vehicle_store:health"
      
      Topics.store_streams(:reckon_store)
      #=> "reckon_store:streams"
      
      # Cluster-level topics  
      Topics.cluster_health()
      #=> "cluster:health"
      
      Topics.cluster_topology()
      #=> "cluster:topology"
  """

  @doc """
  Generate a store-specific health monitoring topic.
  Used for publishing health status updates for a specific store.
  """
  def store_health(store_id) when is_atom(store_id) do
    "#{store_id}:health"
  end

  @doc """
  Generate a store-specific lifecycle events topic.
  Used for publishing store startup, shutdown, and state change events.
  """
  def store_lifecycle(store_id) when is_atom(store_id) do
    "#{store_id}:lifecycle"
  end

  @doc """
  Generate a store-specific streams topic.
  Used for publishing stream creation, updates, and deletion events.
  """
  def store_streams(store_id) when is_atom(store_id) do
    "#{store_id}:streams"
  end

  @doc """
  Generate a store-specific replicas topic.
  Used for publishing replica status changes, leader elections, etc.
  """
  def store_replicas(store_id) when is_atom(store_id) do
    "#{store_id}:replicas"
  end

  @doc """
  Generate a store-specific events topic.
  Used for publishing individual event write notifications.
  """
  def store_events(store_id) when is_atom(store_id) do
    "#{store_id}:events"
  end

  @doc """
  Generate a store-specific alerts topic.
  Used for publishing store-specific alerts and warnings.
  """
  def store_alerts(store_id) when is_atom(store_id) do
    "#{store_id}:alerts"
  end

  @doc """
  Generate a store-specific performance metrics topic.
  Used for publishing performance and monitoring data.
  """
  def store_performance(store_id) when is_atom(store_id) do
    "#{store_id}:performance"
  end

  @doc """
  Generate a store-specific subscriptions topic.
  Used for publishing subscription lifecycle events.
  """
  def store_subscriptions(store_id) when is_atom(store_id) do
    "#{store_id}:subscriptions"
  end

  # Cluster-level topics (not store-specific)

  @doc """
  Generate the cluster health monitoring topic.
  Used for cluster-wide health status and node availability.
  """
  def cluster_health do
    "cluster:health"
  end

  @doc """
  Generate the cluster topology changes topic.
  Used for node join/leave events and cluster membership changes.
  """
  def cluster_topology do
    "cluster:topology"
  end

  @doc """
  Generate the cluster leader election topic.
  Used for leadership changes and coordination events.
  """
  def cluster_leader do
    "cluster:leader"
  end

  @doc """
  Generate the cluster discovery topic.
  Used for node discovery and cluster formation events.
  """
  def cluster_discovery do
    "cluster:discovery"
  end

  @doc """
  Generate the cluster alerts topic.
  Used for cluster-wide alerts and system notifications.
  """
  def cluster_alerts do
    "cluster:alerts"
  end

  @doc """
  Generate the cluster performance topic.
  Used for cluster-wide performance metrics and monitoring.
  """
  def cluster_performance do
    "cluster:performance"
  end

  # Generic topic builder for custom scenarios

  @doc """
  Generate a custom store-specific topic.
  
  ## Examples
  
      Topics.store_topic(:vehicle_store, :custom_events)
      #=> "vehicle_store:custom_events"
  """
  def store_topic(store_id, sub_topic) when is_atom(store_id) and is_atom(sub_topic) do
    "#{store_id}:#{sub_topic}"
  end

  @doc """
  Generate a custom cluster-level topic.
  
  ## Examples
  
      Topics.cluster_topic(:maintenance)
      #=> "cluster:maintenance"
  """
  def cluster_topic(sub_topic) when is_atom(sub_topic) do
    "cluster:#{sub_topic}"
  end

  # Validation and introspection

  @doc """
  Validate if a topic follows the expected pattern.
  
  ## Examples
  
      Topics.valid_topic?("vehicle_store:health")
      #=> true
      
      Topics.valid_topic?("cluster:topology") 
      #=> true
      
      Topics.valid_topic?("invalid-format")
      #=> false
  """
  def valid_topic?(topic) when is_binary(topic) do
    case String.split(topic, ":", parts: 2) do
      [_prefix, _suffix] -> true
      _ -> false
    end
  end

  @doc """
  Parse a topic string into its components.
  
  ## Examples
  
      Topics.parse_topic("vehicle_store:health")
      #=> {:store, :vehicle_store, :health}
      
      Topics.parse_topic("cluster:topology")
      #=> {:cluster, nil, :topology}
      
      Topics.parse_topic("invalid")
      #=> {:error, :invalid_format}
  """
  def parse_topic(topic) when is_binary(topic) do
    case String.split(topic, ":", parts: 2) do
      ["cluster", sub_topic] ->
        {:cluster, nil, String.to_atom(sub_topic)}
      
      [store_part, sub_topic] ->
        store_id = String.to_atom(store_part)
        sub_topic_atom = String.to_atom(sub_topic)
        {:store, store_id, sub_topic_atom}
      
      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Get all predefined store-specific sub-topic types.
  """
  def store_sub_topics do
    [:health, :lifecycle, :streams, :replicas, :events, :alerts, :performance, :subscriptions]
  end

  @doc """
  Get all predefined cluster-level sub-topic types.
  """
  def cluster_sub_topics do
    [:health, :topology, :leader, :discovery, :alerts, :performance]
  end

  @doc """
  Check if a store ID is valid (non-empty atom).
  """
  def valid_store_id?(store_id) when is_atom(store_id) and store_id != nil and store_id != :"" do
    true
  end
  def valid_store_id?(_), do: false

  @doc """
  Generate all standard topics for a given store.
  
  ## Examples
  
      Topics.all_store_topics(:vehicle_store)
      #=> ["vehicle_store:health", "vehicle_store:lifecycle", ...]
  """
  def all_store_topics(store_id) when is_atom(store_id) do
    store_sub_topics()
    |> Enum.map(&store_topic(store_id, &1))
  end

  @doc """
  Generate all standard cluster topics.
  """
  def all_cluster_topics do
    cluster_sub_topics()
    |> Enum.map(&cluster_topic/1)
  end
end
