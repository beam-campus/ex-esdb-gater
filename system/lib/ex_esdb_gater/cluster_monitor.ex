defmodule ExESDBGater.ClusterMonitor do
  @moduledoc """
  Monitors cluster node connections and logs when ExESDBGater connects to or disconnects from cluster nodes.

  This module subscribes to libcluster node events and provides detailed logging of cluster formation.
  It uses RPC calls to reliably identify ExESDB nodes by checking if the :ex_esdb application is running,
  rather than relying on fragile node name pattern matching.
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

    IO.puts(Themes.cluster_monitor(self(), "🔭 watching for node connections"))

    # Log current connected nodes at startup
    connected_nodes = Node.list()

    if length(connected_nodes) > 0 do
      IO.puts(
        Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(connected_nodes)}")
      )
    else
      IO.puts(Themes.cluster_monitor(self(), "📊 No cluster nodes currently connected"))
    end

    # Initialize state with caching for node type identification
    {:ok,
     %{
       connected_nodes: MapSet.new(connected_nodes),
       # Cache node types to avoid repeated RPC calls
       # Format: %{node => {type, timestamp}}
       node_type_cache: %{},
       # Cache TTL in milliseconds (5 minutes)
       cache_ttl: 5 * 60 * 1000
     }}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    IO.puts(Themes.cluster_monitor(self(), "🟢 Connected to cluster node: #{inspect(node)}"))
    IO.puts(Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(Node.list())}"))

    # Check if this is an ExESDB node specifically
    {is_ex_esdb, updated_state} = check_ex_esdb_node(node, state)

    if is_ex_esdb do
      IO.puts(
        Themes.cluster_monitor(
          self(),
          "✅ Successfully connected to ExESDB cluster node: #{inspect(node)}"
        )
      )

      log_cluster_status(updated_state)
    end

    new_connected = MapSet.put(updated_state.connected_nodes, node)
    {:noreply, %{updated_state | connected_nodes: new_connected}}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    IO.puts(Themes.cluster_monitor(self(), "🔴 Disconnected from cluster node: #{inspect(node)}"))
    IO.puts(Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(Node.list())}"))

    # Check cached information for the disconnected node
    if cached_ex_esdb_node?(node, state) do
      IO.puts(
        Themes.cluster_monitor(
          self(),
          "❌ Lost connection to ExESDB cluster node: #{inspect(node)}"
        )
      )
    end

    # Clean up cache entry for disconnected node and update connected nodes
    updated_cache = Map.delete(state.node_type_cache, node)
    new_connected = MapSet.delete(state.connected_nodes, node)

    {:noreply, %{state | connected_nodes: new_connected, node_type_cache: updated_cache}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug(Themes.cluster_monitor(self(), "‼️ Received unexpected message: #{inspect(msg)}"))
    {:noreply, state}
  end

  # Private helper functions

  defp check_ex_esdb_node(node, state) do
    now = System.monotonic_time(:millisecond)

    case Map.get(state.node_type_cache, node) do
      {cached_result, timestamp} when now - timestamp < state.cache_ttl ->
        # Cache hit and still valid
        {cached_result, state}

      _ ->
        # Cache miss or expired, perform RPC check
        is_ex_esdb = perform_ex_esdb_check(node)
        updated_cache = Map.put(state.node_type_cache, node, {is_ex_esdb, now})
        updated_state = %{state | node_type_cache: updated_cache}
        {is_ex_esdb, updated_state}
    end
  end

  defp cached_ex_esdb_node?(node, state) do
    case Map.get(state.node_type_cache, node) do
      {cached_result, _timestamp} -> cached_result
      _ -> false
    end
  end

  defp perform_ex_esdb_check(node) do
    # Use RPC to check if the ex_esdb application is running on the node
    # This is much more reliable than checking node names
    case :rpc.call(node, :application, :which_applications, [], 5_000) do
      {:badrpc, reason} ->
        Logger.debug("RPC call failed for node #{inspect(node)}: #{inspect(reason)}")
        false

      apps when is_list(apps) ->
        apps
        |> Enum.any?(fn {app, _, _} -> app == :ex_esdb end)

      _ ->
        false
    end
  end

  defp log_cluster_status(state) do
    all_nodes = Node.list()

    # Use cached information when available to avoid excessive RPC calls
    ex_esdb_nodes = filter_ex_esdb_nodes(all_nodes, state)

    IO.puts(Themes.cluster_monitor(self(), "🏦️  Cluster Status:"))
    IO.puts(Themes.cluster_monitor(self(), "- Total nodes: #{length(all_nodes)}"))

    if length(ex_esdb_nodes) > 0 do
      IO.puts(Themes.cluster_monitor(self(), "- ExESDB nodes: #{inspect(ex_esdb_nodes)}"))
    end
  end

  defp filter_ex_esdb_nodes(nodes, state) do
    Enum.filter(nodes, fn node ->
      case Map.get(state.node_type_cache, node) do
        {cached_result, _timestamp} -> cached_result
        # Fallback to RPC if not cached
        _ -> perform_ex_esdb_check(node)
      end
    end)
  end
end
