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

    IO.puts(Themes.cluster_monitor(self(), "🚀 started - watching for node connections"))

    # Log current connected nodes at startup
    connected_nodes = Node.list()

    if length(connected_nodes) > 0 do
      IO.puts(
        Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(connected_nodes)}")
      )
    else
      IO.puts(Themes.cluster_monitor(self(), "No cluster nodes currently connected"))
    end

    {:ok, %{connected_nodes: MapSet.new(connected_nodes)}}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    IO.puts(Themes.cluster_monitor(self(), "🟢 Connected to cluster node: #{inspect(node)}"))
    IO.puts(Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(Node.list())}"))

    # Check if this is an ExESDB node specifically
    if is_ex_esdb_node?(node) do
      IO.puts(
        Themes.cluster_monitor(
          self(),
          "✅ Successfully connected to ExESDB cluster node: #{inspect(node)}"
        )
      )

      log_cluster_status()
    end

    new_connected = MapSet.put(state.connected_nodes, node)
    {:noreply, %{state | connected_nodes: new_connected}}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    IO.puts(Themes.cluster_monitor(self(), "🔴 Disconnected from cluster node: #{inspect(node)}"))
    IO.puts(Themes.cluster_monitor(self(), "📊 Total connected nodes: #{length(Node.list())}"))

    if is_ex_esdb_node?(node) do
      IO.puts(
        Themes.cluster_monitor(
          self(),
          "❌ Lost connection to ExESDB cluster node: #{inspect(node)}"
        )
      )
    end

    new_connected = MapSet.delete(state.connected_nodes, node)
    {:noreply, %{state | connected_nodes: new_connected}}
  end

  @impl true
  def handle_info({:cluster_event, event}, state) do
    case event do
      {:connect, node} ->
        IO.puts(
          Themes.cluster_monitor(self(), "🔗 LibCluster connect event for node: #{inspect(node)}")
        )

      {:disconnect, node} ->
        IO.puts(
          Themes.cluster_monitor(
            self(),
            "💔 LibCluster disconnect event for node: #{inspect(node)}"
          )
        )

      other ->
        Logger.debug(Themes.cluster_monitor(self(), "📡 LibCluster event: #{inspect(other)}"))
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug(Themes.cluster_monitor(self(), "Received unexpected message: #{inspect(msg)}"))
    {:noreply, state}
  end

  # Private helper functions

  defp is_ex_esdb_node?(node) do
    node_str = Atom.to_string(node)
    String.contains?(node_str, "ex_esdb") or String.contains?(node_str, "esdb")
  end

  defp log_cluster_status do
    all_nodes = Node.list()

    ex_esdb_nodes =
      all_nodes
      |> Enum.filter(&is_ex_esdb_node?/1)

    IO.puts(Themes.cluster_monitor(self(), "🏛️  Cluster Status:"))
    IO.puts(Themes.cluster_monitor(self(), "- Total nodes: #{length(all_nodes)}"))

    if length(ex_esdb_nodes) > 0 do
      IO.puts(Themes.cluster_monitor(self(), "- ExESDB nodes: #{inspect(ex_esdb_nodes)}"))
    end
  end
end
