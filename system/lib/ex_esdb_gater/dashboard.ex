defmodule ExESDBGater.Dashboard do
  @moduledoc """
  Composable cluster dashboard components that can be embedded 
  in any Phoenix application using ex_esdb_gater as a dependency.
  
  ## Usage
  
  Add to your Phoenix router:
  
      import ExESDBGater.Dashboard
      
      scope "/admin" do
        dashboard_routes()
      end
      
  Or mount individual components:
  
      live "/cluster", ExESDBGater.Dashboard.ClusterLive
      
  ## Requirements
  
  Your hosting application must have:
  - `phoenix_live_view` in dependencies
  - `ExESDBGater.System` started in your supervision tree
  - Phoenix.PubSub configured (using the same pubsub server as ExESDBGater)
  """

  @doc """
  Returns the main cluster dashboard LiveView component.
  """
  def cluster_live_component, do: ExESDBGater.Dashboard.ClusterLive

  @doc """
  Returns the cluster status component for embedding in other views.
  """
  def cluster_status_component, do: ExESDBGater.Dashboard.ClusterStatus

  @doc """
  Adds dashboard routes to a Phoenix router.
  
  ## Example
  
      scope "/admin" do
        dashboard_routes()
      end
  """
  defmacro dashboard_routes do
    quote do
      import Phoenix.LiveView.Router
      
      live "/", ExESDBGater.Dashboard.ClusterLive, :home
      live "/cluster", ExESDBGater.Dashboard.ClusterLive, :cluster
    end
  end

  @doc """
  Gets comprehensive cluster data for dashboard display.
  
  Returns a map containing:
  - `:nodes` - List of connected nodes with their status
  - `:stores` - List of available stores with statistics
  - `:total_streams` - Total number of streams across all stores
  - `:cluster_health` - Overall cluster health status
  """
  def get_cluster_data do
    %{
      nodes: get_cluster_nodes(),
      stores: get_cluster_stores(), 
      total_streams: get_total_streams(),
      cluster_health: get_cluster_health(),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Gets information about all cluster nodes.
  """
  def get_cluster_nodes do
    connected_nodes = Node.list()
    
    nodes_info = 
      connected_nodes
      |> Enum.map(fn node ->
        %{
          name: node,
          status: :connected,
          is_ex_esdb: is_ex_esdb_node?(node),
          uptime: get_node_uptime(node),
          last_seen: DateTime.utc_now()
        }
      end)
    
    # Add self node
    [%{
      name: Node.self(),
      status: :self,
      is_ex_esdb: false,  # This is the gater node
      uptime: get_self_uptime(),
      last_seen: DateTime.utc_now()
    } | nodes_info]
  end

  @doc """
  Gets information about cluster stores.
  """
  def get_cluster_stores do
    case ExESDBGater.API.list_stores() do
      {:ok, stores} when is_list(stores) ->
        stores
        |> Enum.map(fn store_info ->
          store_id = Map.get(store_info, :store_id) || Map.get(store_info, "store_id")
          
          %{
            id: store_id,
            name: to_string(store_id),
            stream_count: get_store_stream_count(store_id),
            subscription_count: get_store_subscription_count(store_id),
            status: :healthy,
            nodes: get_store_nodes(store_id)
          }
        end)
        
      {:error, reason} ->
        require Logger
        Logger.warning("Failed to get stores: #{inspect(reason)}")
        []
        
      _ ->
        []
    end
  end

  # Private helper functions
  
  defp is_ex_esdb_node?(node) do
    case :rpc.call(node, :application, :which_applications, [], 2_000) do
      apps when is_list(apps) ->
        Enum.any?(apps, fn {app, _, _} -> app == :ex_esdb end)
      _ ->
        false
    end
  end

  defp get_node_uptime(node) do
    case :rpc.call(node, :erlang, :statistics, [:wall_clock], 2_000) do
      {uptime_ms, _} when is_integer(uptime_ms) ->
        uptime_ms
      _ ->
        0
    end
  end

  defp get_self_uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_ms
  end

  defp get_store_stream_count(store_id) do
    case ExESDBGater.API.get_streams(store_id) do
      {:ok, streams} when is_list(streams) -> length(streams)
      _ -> 0
    end
  end

  defp get_store_subscription_count(store_id) do
    case ExESDBGater.API.get_subscriptions(store_id) do
      {:ok, subscriptions} when is_list(subscriptions) -> length(subscriptions)
      _ -> 0
    end
  end

  defp get_store_nodes(store_id) do
    ExESDBGater.API.gateway_worker_pids_for_store(store_id)
    |> Enum.map(fn pid ->
      case Process.info(pid, :registered_name) do
        {:registered_name, name} -> extract_node_from_name(name)
        _ -> node(pid)
      end
    end)
    |> Enum.uniq()
  end

  defp extract_node_from_name({:gateway_worker, _store, node, _port}), do: node
  defp extract_node_from_name(_), do: :unknown

  defp get_total_streams do
    get_cluster_stores()
    |> Enum.reduce(0, fn store, acc -> acc + store.stream_count end)
  end

  defp get_cluster_health do
    nodes = get_cluster_nodes()
    stores = get_cluster_stores()
    
    ex_esdb_nodes = Enum.count(nodes, & &1.is_ex_esdb)
    healthy_stores = Enum.count(stores, & &1.status == :healthy)
    
    cond do
      ex_esdb_nodes == 0 -> :no_cluster
      healthy_stores == 0 -> :no_stores  
      ex_esdb_nodes >= 3 and healthy_stores > 0 -> :healthy
      ex_esdb_nodes >= 1 and healthy_stores > 0 -> :degraded
      true -> :unhealthy
    end
  end
end
