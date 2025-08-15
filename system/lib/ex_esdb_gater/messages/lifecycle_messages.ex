defmodule ExESDBGater.Messages.LifecycleMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_lifecycle PubSub instance.

  Handles process lifecycle events, node management, and process state changes.

  ## Common Topics
  - "node_lifecycle" - Node joining/leaving cluster
  - "process_lifecycle" - Process start/stop/crash events
  - "supervision" - Supervisor tree events
  - "cluster_membership" - Cluster membership changes
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_lifecycle

  # Message payload structs

  @doc "Node lifecycle event payload"
  defmodule NodeLifecycle do
    defstruct [
    :node,           # atom - node name
    :event,          # :joining | :joined | :leaving | :left | :down | :reconnected
    :cluster_size,   # integer - size of cluster after event
    :metadata,       # map - additional node information
    :timestamp       # DateTime.t
  ]
  end

  @doc "Process lifecycle event payload"
  defmodule ProcessLifecycle do
    defstruct [
    :pid,            # pid - process identifier
    :name,           # atom - registered process name (if any)
    :module,         # atom - module of the process
    :event,          # :started | :stopped | :crashed | :restarted
    :node,           # atom - node where process is running
    :reason,         # any - exit reason (for crashes)
    :restart_count,  # integer - number of restarts (if applicable)
    :timestamp       # DateTime.t
  ]
  end

  @doc "Supervision tree event payload"
  defmodule SupervisionEvent do
    defstruct [
    :supervisor,     # atom - supervisor name or pid
    :child_spec,     # map - child specification
    :event,          # :child_started | :child_terminated | :restart_limit_exceeded
    :node,           # atom - node where supervisor is running
    :reason,         # any - termination reason
    :timestamp       # DateTime.t
  ]
  end

  @doc "Cluster membership change payload"
  defmodule ClusterMembership do
    defstruct [
    :event,          # :node_added | :node_removed | :partition_detected | :partition_healed
    :affected_nodes, # [atom] - nodes affected by the change
    :active_nodes,   # [atom] - currently active nodes
    :total_nodes,    # integer - total nodes known to cluster
    :quorum_status,  # :available | :lost
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a node lifecycle event"
  def broadcast_node_lifecycle(topic, %NodeLifecycle{} = payload) do
    secure_broadcast(topic, {:node_lifecycle_event, payload})
  end

  @doc "Broadcast a process lifecycle event"
  def broadcast_process_lifecycle(topic, %ProcessLifecycle{} = payload) do
    secure_broadcast(topic, {:process_lifecycle_event, payload})
  end

  @doc "Broadcast a supervision event"
  def broadcast_supervision_event(topic, %SupervisionEvent{} = payload) do
    secure_broadcast(topic, {:supervision_event, payload})
  end

  @doc "Broadcast a cluster membership change"
  def broadcast_cluster_membership(topic, %ClusterMembership{} = payload) do
    secure_broadcast(topic, {:cluster_membership_changed, payload})
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

  @doc "Create a NodeLifecycle payload with current timestamp"
  def node_lifecycle(node, event, cluster_size, opts \\ []) do
    %NodeLifecycle{
      node: node,
      event: event,
      cluster_size: cluster_size,
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ProcessLifecycle payload with current timestamp"
  def process_lifecycle(pid, module, event, opts \\ []) do
    %ProcessLifecycle{
      pid: pid,
      name: Keyword.get(opts, :name),
      module: module,
      event: event,
      node: Keyword.get(opts, :node, Node.self()),
      reason: Keyword.get(opts, :reason),
      restart_count: Keyword.get(opts, :restart_count, 0),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a SupervisionEvent payload with current timestamp"
  def supervision_event(supervisor, child_spec, event, opts \\ []) do
    %SupervisionEvent{
      supervisor: supervisor,
      child_spec: child_spec,
      event: event,
      node: Keyword.get(opts, :node, Node.self()),
      reason: Keyword.get(opts, :reason),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ClusterMembership payload with current timestamp"
  def cluster_membership(event, affected_nodes, active_nodes, opts \\ []) do
    %ClusterMembership{
      event: event,
      affected_nodes: affected_nodes,
      active_nodes: active_nodes,
      total_nodes: Keyword.get(opts, :total_nodes, length(active_nodes)),
      quorum_status: Keyword.get(opts, :quorum_status, :available),
      timestamp: DateTime.utc_now()
    }
  end

  # Private security functions

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
