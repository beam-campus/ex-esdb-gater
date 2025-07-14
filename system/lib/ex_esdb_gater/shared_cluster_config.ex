defmodule ExESDBGater.SharedClusterConfig do
  @moduledoc """
  Unified LibCluster configuration to prevent conflicts between ExESDB and ExESDBGater.

  This module ensures both applications use identical cluster topology settings,
  preventing discovery protocol confusion and startup race conditions.
  """

  @doc """
  Returns the unified cluster topology configuration.
  Both ExESDB and ExESDBGater should use this exact configuration.
  """
  def topology do
    [
      ex_esdb_cluster: [
        strategy: Cluster.Strategy.Gossip,
        config: [
          port: cluster_port(),
          if_addr: interface_addr(),
          multicast_addr: multicast_addr(),
          broadcast_only: false,
          secret: cluster_secret()
        ]
      ]
    ]
  end

  @doc """
  Get the cluster port from environment or default.
  """
  def cluster_port do
    case System.get_env("EX_ESDB_CLUSTER_PORT") do
      nil -> 45_892
      port_str -> String.to_integer(port_str)
    end
  end

  @doc """
  Get the network interface address from environment or default.
  """
  def interface_addr do
    System.get_env("EX_ESDB_CLUSTER_INTERFACE") || "0.0.0.0"
  end

  @doc """
  Get the multicast address from environment or default.
  Uses consistent multicast address (not broadcast).
  """
  def multicast_addr do
    System.get_env("EX_ESDB_GOSSIP_MULTICAST_ADDR") || "239.255.0.1"
  end

  @doc """
  Get the cluster secret from environment or default.
  """
  def cluster_secret do
    System.get_env("EX_ESDB_CLUSTER_SECRET") || "dev_cluster_secret"
  end

  @doc """
  Validate the cluster configuration and log any issues.
  """
  def validate_config do
    config = topology()[:ex_esdb_cluster][:config]

    issues = []

    # Check for potential issues
    issues =
      if config[:if_addr] == "0.0.0.0" and System.get_env("CONTAINER_ENV") do
        [
          "Warning: Using 0.0.0.0 interface in containerized environment may cause issues"
          | issues
        ]
      else
        issues
      end

    issues =
      if config[:multicast_addr] == "255.255.255.255" do
        [
          "Warning: Using broadcast address instead of multicast may cause network issues"
          | issues
        ]
      else
        issues
      end

    case issues do
      [] -> :ok
      _ -> {:warning, issues}
    end
  end
end
