defmodule ExESDBGater.Messages.HealthMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_health PubSub instance.

  Handles health monitoring, status checks, and health-related events.

  ## Common Topics
  - "node_health" - Individual node health status
  - "cluster_health" - Overall cluster health  
  - "component_health" - Health of specific components
  - "health_checks" - Health check results
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_health

  # Message payload structs

  @doc "Node health status payload"
  defmodule NodeHealth do
    defstruct [
    :node,           # atom - node name
    :status,         # :healthy | :degraded | :unhealthy | :unknown
    :checks,         # map - individual health check results
    :load_avg,       # float - system load average
    :memory_usage,   # float - memory usage percentage
    :disk_usage,     # float - disk usage percentage
    :timestamp       # DateTime.t
  ]
  end

  @doc "Cluster health overview payload"
  defmodule ClusterHealth do
    defstruct [
    :status,         # :healthy | :degraded | :unhealthy
    :healthy_nodes,  # integer - count of healthy nodes
    :total_nodes,    # integer - total nodes in cluster
    :degraded_nodes, # [atom] - list of degraded nodes
    :unhealthy_nodes, # [atom] - list of unhealthy nodes
    :quorum_status,  # :available | :lost
    :timestamp       # DateTime.t
  ]
  end

  @doc "Component health status payload"
  defmodule ComponentHealth do
    defstruct [
    :component,      # atom - component name
    :node,           # atom - node where component is running
    :status,         # :healthy | :degraded | :unhealthy
    :details,        # map - component-specific health info
    :last_check,     # DateTime.t - when last checked
    :timestamp       # DateTime.t
  ]
  end

  @doc "Health check result payload"
  defmodule HealthCheck do
    defstruct [
    :check_name,     # atom - name of the health check
    :node,           # atom - node where check ran
    :result,         # :pass | :fail | :timeout
    :duration_ms,    # integer - how long check took
    :details,        # map - check-specific details
    :error,          # string - error message if failed
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a node health update"
  def broadcast_node_health(topic, %NodeHealth{} = payload) do
    secure_broadcast(topic, {:node_health_updated, payload})
  end

  @doc "Broadcast a cluster health update"
  def broadcast_cluster_health(topic, %ClusterHealth{} = payload) do
    secure_broadcast(topic, {:cluster_health_updated, payload})
  end

  @doc "Broadcast a component health update"
  def broadcast_component_health(topic, %ComponentHealth{} = payload) do
    secure_broadcast(topic, {:component_health_updated, payload})
  end

  @doc "Broadcast a health check result"
  def broadcast_health_check(topic, %HealthCheck{} = payload) do
    secure_broadcast(topic, {:health_check_completed, payload})
  end

  # Generic secure broadcasting
  def secure_broadcast(topic, message) when is_binary(topic) do
    case get_secret_key() do
      {:ok, _secret} ->
        secured_message = add_security_signature(message)
        PubSub.broadcast(@pubsub_instance, topic, secured_message)
      
      {:error, :no_secret} ->
        require Logger
        Logger.warning("Broadcasting unsecured message - no SECRET_KEY_BASE configured")
        PubSub.broadcast(@pubsub_instance, topic, {:unsecured_message, message})
    end
  end

  @doc "Validate and extract a secure message"
  def validate_secure_message({:secure_message, signature, original_message}) do
    case get_secret_key() do
      {:ok, _secret} ->
        expected_signature = generate_signature(original_message)
        
        if :crypto.hash_equals(signature, expected_signature) do
          {:ok, original_message}
        else
          {:error, :invalid_signature}
        end
      
      {:error, :no_secret} ->
        {:error, :no_secret_configured}
    end
  end

  def validate_secure_message({:unsecured_message, original_message}) do
    case get_secret_key() do
      {:ok, _secret} ->
        {:error, :unsecured_message_rejected}
      
      {:error, :no_secret} ->
        require Logger
        Logger.warning("Accepting unsecured message - no SECRET_KEY_BASE configured")
        {:ok, original_message}
    end
  end

  def validate_secure_message(_), do: {:error, :invalid_format}

  # Helper functions for creating payload structs

  @doc "Create a NodeHealth payload with current timestamp"
  def node_health(node, status, opts \\ []) do
    %NodeHealth{
      node: node,
      status: status,
      checks: Keyword.get(opts, :checks, %{}),
      load_avg: Keyword.get(opts, :load_avg),
      memory_usage: Keyword.get(opts, :memory_usage),
      disk_usage: Keyword.get(opts, :disk_usage),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ClusterHealth payload with current timestamp"
  def cluster_health(status, healthy_nodes, total_nodes, opts \\ []) do
    %ClusterHealth{
      status: status,
      healthy_nodes: healthy_nodes,
      total_nodes: total_nodes,
      degraded_nodes: Keyword.get(opts, :degraded_nodes, []),
      unhealthy_nodes: Keyword.get(opts, :unhealthy_nodes, []),
      quorum_status: Keyword.get(opts, :quorum_status, :available),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ComponentHealth payload with current timestamp"
  def component_health(component, node, status, opts \\ []) do
    %ComponentHealth{
      component: component,
      node: node,
      status: status,
      details: Keyword.get(opts, :details, %{}),
      last_check: Keyword.get(opts, :last_check),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a HealthCheck payload with current timestamp"
  def health_check(check_name, node, result, opts \\ []) do
    %HealthCheck{
      check_name: check_name,
      node: node,
      result: result,
      duration_ms: Keyword.get(opts, :duration_ms),
      details: Keyword.get(opts, :details, %{}),
      error: Keyword.get(opts, :error),
      timestamp: DateTime.utc_now()
    }
  end

  # Private security functions (shared pattern)

  defp add_security_signature(message) do
    signature = generate_signature(message)
    {:secure_message, signature, message}
  end

  defp generate_signature(message) do
    {:ok, secret_key} = get_secret_key()
    message_binary = :erlang.term_to_binary(message)
    :crypto.mac(:hmac, :sha256, secret_key, message_binary)
  end

  defp get_secret_key do
    cond do
      secret = Application.get_env(:ex_esdb_gater, :secret_key_base) ->
        {:ok, secret}
      
      secret = System.get_env("SECRET_KEY_BASE") ->
        {:ok, secret}
      
      secret = Application.get_env(:phoenix, :secret_key_base) ->
        {:ok, secret}
      
      true ->
        {:error, :no_secret}
    end
  end
end
