defmodule ExESDBGater.Telemetry do
  @moduledoc """
  Telemetry GenServer for the ExESDBGater package.
  
  This module is responsible only for monitoring and observability within
  the ex_esdb_gater package. It follows proper separation of concerns by:
  
  1. Only handling telemetry events from this package
  2. Running as a supervised GenServer for reliability
  3. Broadcasting events through PubSub for external consumption
  4. Maintaining internal metrics and health state
  
  ## Responsibilities
  - Monitor API call performance and load balancing
  - Track gateway worker pool utilization and availability
  - Measure cluster connection health and topology changes
  - Monitor PubSub message throughput
  - Collect system resource usage for this node
  
  ## Gateway Worker Architecture
  Gateway workers are external processes running on ExESDB nodes that are:
  - Registered with Swarm using pattern `{:gateway_worker, store_id, _, _}`
  - Managed by the ExESDBGater.API as a load balancer/proxy
  - Distributed across the cluster for high availability
  
  ## Usage
  
  The telemetry server is automatically started by the ExESDBGater supervisor.
  To emit custom events from your code:
  
      ExESDBGater.Telemetry.emit(:api_call_start, %{function: :get_events})
      ExESDBGater.Telemetry.emit(:gateway_worker_assigned, %{store_id: :my_store, worker_pid: pid})
  
  To get current metrics:
  
      ExESDBGater.Telemetry.get_metrics()
      ExESDBGater.Telemetry.get_health()
  """
  
  use GenServer
  require Logger
  alias Phoenix.PubSub
  
  @pubsub_server :ex_esdb_metrics
  
  # Telemetry events this module handles
  @telemetry_events [
    [:ex_esdb_gater, :api, :call, :start],
    [:ex_esdb_gater, :api, :call, :stop],
    [:ex_esdb_gater, :api, :call, :error],
    [:ex_esdb_gater, :gateway_worker, :assigned],
    [:ex_esdb_gater, :gateway_worker, :released],
    [:ex_esdb_gater, :gateway_worker, :unavailable],
    [:ex_esdb_gater, :cluster, :node, :up],
    [:ex_esdb_gater, :cluster, :node, :down],
    [:ex_esdb_gater, :pubsub, :message, :sent],
    [:ex_esdb_gater, :pubsub, :message, :received],
    [:ex_esdb_gater, :swarm, :registration, :success],
    [:ex_esdb_gater, :swarm, :registration, :failed]
  ]
  
  # Metrics collection interval (30 seconds)
  @metrics_interval 30_000
  
  ## Public API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000,
      type: :worker
    }
  end
  
  @doc """
  Emit a telemetry event from application code.
  
  ## Examples
  
      # API call tracking
      ExESDBGater.Telemetry.emit(:api_call_start, %{function: :get_events, store: :my_store})
      ExESDBGater.Telemetry.emit(:api_call_stop, %{function: :get_events, duration_us: 1500})
      
      # Gateway worker utilization
      ExESDBGater.Telemetry.emit(:gateway_worker_assigned, %{store_id: :my_store, worker_pid: pid})
      ExESDBGater.Telemetry.emit(:gateway_worker_released, %{store_id: :my_store, worker_pid: pid})
      
      # Cluster events
      ExESDBGater.Telemetry.emit(:cluster_node_up, %{node: :node1@host})
  """
  def emit(event_name, metadata \\ %{}) when is_atom(event_name) do
    measurements = %{
      timestamp: System.monotonic_time(:microsecond),
      system_time: System.system_time(:microsecond)
    }
    :telemetry.execute([:ex_esdb_gater, event_name], measurements, metadata)
  end
  
  @doc """
  Get current metrics summary.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end
  
  @doc """
  Get current health status.
  """
  def get_health do
    GenServer.call(__MODULE__, :get_health)
  end
  
  @doc """
  Get gateway worker pool status.
  """
  def get_worker_pool_status do
    GenServer.call(__MODULE__, :get_worker_pool_status)
  end
  
  @doc """
  Reset metrics counters.
  """
  def reset_metrics do
    GenServer.call(__MODULE__, :reset_metrics)
  end
  
  ## GenServer Implementation
  
  @impl true
  def init(opts) do
    # Attach telemetry handlers
    :telemetry.attach_many(
      "ex-esdb-gater-telemetry",
      @telemetry_events,
      &handle_telemetry_event/4,
      %{}
    )
    
    # Schedule periodic metrics collection
    Process.send_after(self(), :collect_metrics, @metrics_interval)
    
    initial_state = %{
      # API performance metrics
      api_calls: %{
        total: 0, 
        errors: 0, 
        avg_duration_us: 0,
        current_calls: 0,
        by_function: %{}
      },
      
      # Gateway worker pool metrics
      gateway_workers: %{
        assignments: 0,
        releases: 0,
        unavailable_attempts: 0,
        active_assignments: 0,
        by_store: %{},
        last_assignment: nil
      },
      
      # Cluster health tracking
      cluster_nodes: %{
        connected: [],
        disconnected: [],
        total_events: 0
      },
      
      # PubSub metrics
      pubsub_messages: %{
        sent: 0,
        received: 0,
        by_topic: %{}
      },
      
      # Swarm registration tracking
      swarm_registrations: %{
        successes: 0,
        failures: 0,
        last_registration: nil
      },
      
      # System metrics
      system_metrics: %{},
      last_metrics_collection: DateTime.utc_now(),
      
      # Performance tracking for alerts
      performance_issues: [],
      
      # Configuration
      config: Map.new(opts)
    }
    
    Logger.info("ExESDBGater.Telemetry started successfully")
    {:ok, initial_state}
  end
  
  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = %{
      api_calls: state.api_calls,
      gateway_workers: calculate_worker_metrics(state.gateway_workers),
      cluster_nodes: %{
        connected_count: length(state.cluster_nodes.connected),
        disconnected_count: length(state.cluster_nodes.disconnected),
        total_cluster_size: length(Node.list()) + 1,
        cluster_events: state.cluster_nodes.total_events
      },
      pubsub_messages: state.pubsub_messages,
      swarm_registrations: state.swarm_registrations,
      system_metrics: state.system_metrics,
      last_updated: state.last_metrics_collection
    }
    
    {:reply, metrics, state}
  end
  
  @impl true
  def handle_call(:get_health, _from, state) do
    health = %{
      status: calculate_overall_health(state),
      api_health: calculate_api_health(state),
      worker_pool_health: calculate_worker_pool_health(state),
      cluster_health: calculate_cluster_health(state),
      node: Node.self(),
      timestamp: DateTime.utc_now()
    }
    
    {:reply, health, state}
  end
  
  @impl true
  def handle_call(:get_worker_pool_status, _from, state) do
    # Get current worker pool status from Swarm
    available_workers = ExESDBGater.API.gateway_worker_pids()
    workers_by_store = get_workers_by_store()
    
    status = %{
      available_workers: length(available_workers),
      workers_by_store: workers_by_store,
      active_assignments: state.gateway_workers.active_assignments,
      total_assignments: state.gateway_workers.assignments,
      unavailable_attempts: state.gateway_workers.unavailable_attempts,
      assignment_success_rate: calculate_assignment_success_rate(state.gateway_workers)
    }
    
    {:reply, status, state}
  end
  
  @impl true
  def handle_call(:reset_metrics, _from, state) do
    reset_state = %{state |
      api_calls: %{total: 0, errors: 0, avg_duration_us: 0, current_calls: 0, by_function: %{}},
      gateway_workers: %{assignments: 0, releases: 0, unavailable_attempts: 0, active_assignments: 0, by_store: %{}, last_assignment: nil},
      pubsub_messages: %{sent: 0, received: 0, by_topic: %{}},
      swarm_registrations: %{successes: 0, failures: 0, last_registration: nil},
      performance_issues: []
    }
    
    {:reply, :ok, reset_state}
  end
  
  @impl true
  def handle_info(:collect_metrics, state) do
    # Collect system metrics
    system_metrics = collect_system_metrics()
    
    # Broadcast current state
    broadcast_metrics_update(state, system_metrics)
    
    # Schedule next collection
    Process.send_after(self(), :collect_metrics, @metrics_interval)
    
    updated_state = %{state |
      system_metrics: system_metrics,
      last_metrics_collection: DateTime.utc_now()
    }
    
    {:noreply, updated_state}
  end
  
  @impl true
  def handle_info({:telemetry_event, event, measurements, metadata}, state) do
    updated_state = process_telemetry_event(event, measurements, metadata, state)
    {:noreply, updated_state}
  end
  
  @impl true
  def handle_info(msg, state) do
    Logger.debug("ExESDBGater.Telemetry received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
  
  @impl true
  def terminate(reason, _state) do
    # Detach telemetry handlers
    :telemetry.detach("ex-esdb-gater-telemetry")
    Logger.info("ExESDBGater.Telemetry terminated: #{inspect(reason)}")
    :ok
  end
  
  ## Private Functions
  
  # Telemetry event handler (runs in caller's process)
  defp handle_telemetry_event(event, measurements, metadata, _config) do
    # Send to GenServer for processing (non-blocking)
    send(__MODULE__, {:telemetry_event, event, measurements, metadata})
  end
  
  ## Pattern-matched telemetry event processors
  
  # API call events
  defp process_telemetry_event([:ex_esdb_gater, :api, :call, :start], _measurements, metadata, state) do
    function = Map.get(metadata, :function, :unknown)
    
    updated_api_calls = %{state.api_calls |
      current_calls: state.api_calls.current_calls + 1,
      by_function: Map.update(state.api_calls.by_function, function, 1, &(&1 + 1))
    }
    
    %{state | api_calls: updated_api_calls}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :api, :call, :stop], measurements, metadata, state) do
    duration_us = Map.get(measurements, :duration, 0)
    
    current_calls = state.api_calls
    new_total = current_calls.total + 1
    current_active = max(0, current_calls.current_calls - 1)
    
    # Calculate new average duration (microseconds)
    current_avg = current_calls.avg_duration_us
    new_avg = if new_total > 1 do
      (current_avg * (new_total - 1) + duration_us) / new_total
    else
      duration_us
    end
    
    updated_api_calls = %{current_calls |
      total: new_total,
      avg_duration_us: new_avg,
      current_calls: current_active
    }
    
    # Check for performance issues (> 5 seconds)
    if duration_us > 5_000_000 do
      broadcast_performance_alert(:slow_api_call, metadata, duration_us)
    end
    
    %{state | api_calls: updated_api_calls}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :api, :call, :error], _measurements, metadata, state) do
    updated_api_calls = %{state.api_calls |
      errors: state.api_calls.errors + 1,
      current_calls: max(0, state.api_calls.current_calls - 1)
    }
    
    broadcast_performance_alert(:api_call_error, metadata, nil)
    
    %{state | api_calls: updated_api_calls}
  end
  
  # Gateway worker events
  defp process_telemetry_event([:ex_esdb_gater, :gateway_worker, :assigned], _measurements, metadata, state) do
    store_id = Map.get(metadata, :store_id, :unknown)
    
    updated_workers = %{state.gateway_workers |
      assignments: state.gateway_workers.assignments + 1,
      active_assignments: state.gateway_workers.active_assignments + 1,
      last_assignment: DateTime.utc_now(),
      by_store: Map.update(state.gateway_workers.by_store, store_id, 1, &(&1 + 1))
    }
    
    broadcast_worker_event(:worker_assigned, metadata)
    
    %{state | gateway_workers: updated_workers}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :gateway_worker, :released], _measurements, _metadata, state) do
    updated_workers = %{state.gateway_workers |
      releases: state.gateway_workers.releases + 1,
      active_assignments: max(0, state.gateway_workers.active_assignments - 1)
    }
    
    %{state | gateway_workers: updated_workers}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :gateway_worker, :unavailable], _measurements, metadata, state) do
    updated_workers = %{state.gateway_workers |
      unavailable_attempts: state.gateway_workers.unavailable_attempts + 1
    }
    
    broadcast_worker_event(:worker_unavailable, metadata)
    
    %{state | gateway_workers: updated_workers}
  end
  
  # Cluster events
  defp process_telemetry_event([:ex_esdb_gater, :cluster, :node, :up], _measurements, metadata, state) do
    node = Map.get(metadata, :node)
    connected_nodes = [node | state.cluster_nodes.connected] |> Enum.uniq()
    disconnected_nodes = List.delete(state.cluster_nodes.disconnected, node)
    
    updated_cluster = %{state.cluster_nodes |
      connected: connected_nodes,
      disconnected: disconnected_nodes,
      total_events: state.cluster_nodes.total_events + 1
    }
    
    broadcast_cluster_event(:node_up, metadata)
    
    %{state | cluster_nodes: updated_cluster}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :cluster, :node, :down], _measurements, metadata, state) do
    node = Map.get(metadata, :node)
    disconnected_nodes = [node | state.cluster_nodes.disconnected] |> Enum.uniq()
    connected_nodes = List.delete(state.cluster_nodes.connected, node)
    
    updated_cluster = %{state.cluster_nodes |
      connected: connected_nodes,
      disconnected: disconnected_nodes,
      total_events: state.cluster_nodes.total_events + 1
    }
    
    broadcast_cluster_event(:node_down, metadata)
    
    %{state | cluster_nodes: updated_cluster}
  end
  
  # PubSub events
  defp process_telemetry_event([:ex_esdb_gater, :pubsub, :message, :sent], _measurements, metadata, state) do
    topic = Map.get(metadata, :topic, :unknown)
    
    updated_pubsub = %{state.pubsub_messages |
      sent: state.pubsub_messages.sent + 1,
      by_topic: Map.update(state.pubsub_messages.by_topic, topic, 1, &(&1 + 1))
    }
    
    %{state | pubsub_messages: updated_pubsub}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :pubsub, :message, :received], _measurements, metadata, state) do
    topic = Map.get(metadata, :topic, :unknown)
    
    updated_pubsub = %{state.pubsub_messages |
      received: state.pubsub_messages.received + 1,
      by_topic: Map.update(state.pubsub_messages.by_topic, topic, 1, &(&1 + 1))
    }
    
    %{state | pubsub_messages: updated_pubsub}
  end
  
  # Swarm registration events
  defp process_telemetry_event([:ex_esdb_gater, :swarm, :registration, :success], _measurements, _metadata, state) do
    updated_swarm = %{state.swarm_registrations |
      successes: state.swarm_registrations.successes + 1,
      last_registration: DateTime.utc_now()
    }
    
    %{state | swarm_registrations: updated_swarm}
  end
  
  defp process_telemetry_event([:ex_esdb_gater, :swarm, :registration, :failed], _measurements, metadata, state) do
    updated_swarm = %{state.swarm_registrations |
      failures: state.swarm_registrations.failures + 1
    }
    
    broadcast_performance_alert(:swarm_registration_failed, metadata, nil)
    
    %{state | swarm_registrations: updated_swarm}
  end
  
  # Catch-all for unknown events
  defp process_telemetry_event(event, _measurements, _metadata, state) do
    Logger.debug("Unknown telemetry event: #{inspect(event)}")
    state
  end
  
  ## Helper Functions
  
  # System metrics collection
  defp collect_system_metrics do
    %{
      memory: :erlang.memory(),
      process_count: length(Process.list()),
      connected_nodes: Node.list(),
      uptime_ms: :erlang.statistics(:uptime) |> elem(0),
      schedulers: :erlang.system_info(:schedulers),
      gateway_workers_available: length(ExESDBGater.API.gateway_worker_pids()),
      timestamp: DateTime.utc_now()
    }
  rescue
    _ -> %{error: "Failed to collect system metrics", timestamp: DateTime.utc_now()}
  end
  
  # Metrics calculations
  defp calculate_worker_metrics(gateway_workers) do
    total_ops = gateway_workers.assignments + gateway_workers.unavailable_attempts
    success_rate = if total_ops > 0 do
      gateway_workers.assignments / total_ops
    else
      1.0
    end
    
    Map.put(gateway_workers, :success_rate, success_rate)
  end
  
  defp calculate_assignment_success_rate(gateway_workers) do
    total_attempts = gateway_workers.assignments + gateway_workers.unavailable_attempts
    if total_attempts > 0 do
      gateway_workers.assignments / total_attempts
    else
      1.0
    end
  end
  
  defp get_workers_by_store do
    try do
      Swarm.registered()
      |> Enum.filter(fn {name, _} -> match?({:gateway_worker, _, _, _}, name) end)
      |> Enum.group_by(fn {{:gateway_worker, store_id, _, _}, _} -> store_id end)
      |> Enum.map(fn {store_id, workers} -> {store_id, length(workers)} end)
      |> Map.new()
    rescue
      _ -> %{}
    end
  end
  
  ## Health Calculations
  
  defp calculate_overall_health(state) do
    api_healthy = calculate_api_health(state) in [:healthy, :degraded]
    worker_healthy = calculate_worker_pool_health(state) in [:healthy, :degraded]
    cluster_healthy = calculate_cluster_health(state) in [:healthy, :degraded]
    
    cond do
      api_healthy and worker_healthy and cluster_healthy -> :healthy
      (api_healthy and worker_healthy) or (api_healthy and cluster_healthy) -> :degraded
      true -> :unhealthy
    end
  end
  
  defp calculate_api_health(state) do
    error_rate = if state.api_calls.total > 0 do
      state.api_calls.errors / state.api_calls.total
    else
      0.0
    end
    
    avg_duration_ms = state.api_calls.avg_duration_us / 1000
    
    cond do
      error_rate < 0.01 and avg_duration_ms < 1000 -> :healthy
      error_rate < 0.05 and avg_duration_ms < 5000 -> :degraded
      true -> :unhealthy
    end
  end
  
  defp calculate_worker_pool_health(state) do
    success_rate = calculate_assignment_success_rate(state.gateway_workers)
    available_workers = length(ExESDBGater.API.gateway_worker_pids())
    
    cond do
      success_rate > 0.95 and available_workers > 0 -> :healthy
      success_rate > 0.80 and available_workers > 0 -> :degraded
      true -> :unhealthy
    end
  rescue
    _ -> :unknown
  end
  
  defp calculate_cluster_health(state) do
    connected_count = length(state.cluster_nodes.connected)
    total_nodes = length(Node.list()) + 1
    
    cond do
      connected_count >= total_nodes * 0.8 -> :healthy
      connected_count >= total_nodes * 0.5 -> :degraded
      true -> :unhealthy
    end
  end
  
  ## Broadcasting Functions
  
  defp broadcast_metrics_update(state, system_metrics) do
    message = %{
      type: :metrics_update,
      package: :ex_esdb_gater,
      node: Node.self(),
      metrics: %{
        api_calls: state.api_calls,
        gateway_workers: calculate_worker_metrics(state.gateway_workers),
        cluster_nodes: state.cluster_nodes,
        pubsub_messages: state.pubsub_messages,
        swarm_registrations: state.swarm_registrations,
        system: system_metrics
      },
      timestamp: DateTime.utc_now()
    }
    
    PubSub.broadcast(@pubsub_server, "gater:metrics", {:metrics_update, message})
  end
  
  defp broadcast_performance_alert(alert_type, metadata, duration) do
    alert = %{
      type: :performance_alert,
      alert: alert_type,
      package: :ex_esdb_gater,
      node: Node.self(),
      duration_us: duration,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }
    
    PubSub.broadcast(@pubsub_server, "gater:alerts", {:performance_alert, alert})
  end
  
  defp broadcast_worker_event(event_type, metadata) do
    event = %{
      type: :worker_event,
      event: event_type,
      package: :ex_esdb_gater,
      node: Node.self(),
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }
    
    PubSub.broadcast(@pubsub_server, "gater:workers", {:worker_event, event})
  end
  
  defp broadcast_cluster_event(event_type, metadata) do
    event = %{
      type: :cluster_event,
      event: event_type,
      package: :ex_esdb_gater,
      node: Node.self(),
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }
    
    PubSub.broadcast(@pubsub_server, "gater:cluster", {:cluster_event, event})
  end
end
