defmodule ExESDBGater.ClusterMonitor do
  @moduledoc """
  Monitors cluster node connections and logs when ExESDBGater connects to or disconnects from cluster nodes.
  
  This module subscribes to libcluster node events and provides detailed logging of cluster formation.
  """
  use GenServer
  require Logger
  alias ExESDBGater.Themes

  @doc """
  Starts the ClusterMonitor GenServer.
  """
  def start_link(opts) do
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

  @impl true
  def init(_opts) do
    # Monitor node connections and disconnections
    :ok = :net_kernel.monitor_nodes(true)
    
    # Subscribe to libcluster events if available
    if Code.ensure_loaded?(Cluster.Events) do
      :ok = Cluster.Events.subscribe()
    end
    
    Logger.info("#{log_prefix()} Cluster monitor started - watching for node connections")
    
    # Log current connected nodes at startup
    connected_nodes = Node.list()
    if length(connected_nodes) > 0 do
      Logger.info("#{log_prefix()} Currently connected to #{length(connected_nodes)} nodes: #{inspect(connected_nodes)}")
    else
      Logger.info("#{log_prefix()} No cluster nodes currently connected")
    end
    
    {:ok, %{connected_nodes: MapSet.new(connected_nodes)}}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("#{log_prefix()} 🟢 Connected to cluster node: #{inspect(node)}")
    Logger.info("#{log_prefix()} 📊 Total connected nodes: #{length(Node.list())}")
    
    # Check if this is an ExESDB node specifically
    if is_ex_esdb_node?(node) do
      Logger.info("#{log_prefix()} ✅ Successfully connected to ExESDB cluster node: #{inspect(node)}")
      log_cluster_status()
    end
    
    new_connected = MapSet.put(state.connected_nodes, node)
    {:noreply, %{state | connected_nodes: new_connected}}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.warning("#{log_prefix()} 🔴 Disconnected from cluster node: #{inspect(node)}")
    Logger.info("#{log_prefix()} 📊 Total connected nodes: #{length(Node.list())}")
    
    if is_ex_esdb_node?(node) do
      Logger.warning("#{log_prefix()} ❌ Lost connection to ExESDB cluster node: #{inspect(node)}")
    end
    
    new_connected = MapSet.delete(state.connected_nodes, node)
    {:noreply, %{state | connected_nodes: new_connected}}
  end

  @impl true
  def handle_info({:cluster_event, event}, state) do
    case event do
      {:connect, node} ->
        Logger.info("#{log_prefix()} 🔗 LibCluster connect event for node: #{inspect(node)}")
      {:disconnect, node} ->
        Logger.info("#{log_prefix()} 💔 LibCluster disconnect event for node: #{inspect(node)}")
      other ->
        Logger.debug("#{log_prefix()} 📡 LibCluster event: #{inspect(other)}")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("#{log_prefix()} Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private helper functions

  defp log_prefix do
    "#{Themes.cluster_monitor(self())} [ClusterMonitor]"
  end

  defp is_ex_esdb_node?(node) do
    node_str = Atom.to_string(node)
    String.contains?(node_str, "ex_esdb") or String.contains?(node_str, "esdb")
  end

  defp log_cluster_status do
    all_nodes = Node.list()
    ex_esdb_nodes = Enum.filter(all_nodes, &is_ex_esdb_node?/1)
    
    Logger.info("#{log_prefix()} 🏛️  Cluster Status:")
    Logger.info("#{log_prefix()} - Total nodes: #{length(all_nodes)}")
    Logger.info("#{log_prefix()} - ExESDB nodes: #{length(ex_esdb_nodes)}")
    
    if length(ex_esdb_nodes) > 0 do
      Logger.info("#{log_prefix()} - ExESDB nodes: #{inspect(ex_esdb_nodes)}")
    end
  end
end
