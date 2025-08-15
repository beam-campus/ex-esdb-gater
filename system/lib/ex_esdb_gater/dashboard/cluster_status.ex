defmodule ExESDBGater.Dashboard.ClusterStatus do
  @moduledoc """
  Standalone cluster status component that can be embedded in other LiveViews.
  
  Displays a compact overview of cluster health and key metrics.
  Automatically updates in real-time via PubSub.
  
  ## Usage
  
  In your LiveView template:
  
      <.live_component 
        module={ExESDBGater.Dashboard.ClusterStatus} 
        id="cluster-status" 
      />
  
  Or use the helper from the main Dashboard module:
  
      <.live_component 
        module={ExESDBGater.Dashboard.cluster_status_component()} 
        id="cluster-status" 
      />
  """
  use Phoenix.LiveComponent
  
  alias ExESDBGater.Dashboard
  
  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    # Load cluster data on first render or when explicitly requested
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(assigns)
      |> assign(:cluster_data, cluster_data)
      |> assign(:last_updated, DateTime.utc_now())
    
    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(:cluster_data, cluster_data)
      |> assign(:last_updated, DateTime.utc_now())
    
    {:noreply, socket}
  end

  # LiveComponents don't receive handle_info messages directly from PubSub.
  # The parent LiveView should forward cluster updates to this component 
  # by calling send_update/3 when it receives PubSub messages.
  #
  # For manual refresh, users can click the refresh button which triggers
  # the "refresh" event handled above.

  @impl true
  def render(assigns) do
    ~H"""
    <div class="cluster-status-widget">
      <div class="widget-header">
        <h3 class="widget-title">Cluster Status</h3>
        <button 
          type="button" 
          phx-click="refresh" 
          phx-target={@myself}
          class="refresh-btn"
          title="Refresh cluster data"
        >
          🔄
        </button>
      </div>

      <div class="widget-content">
        <!-- Health indicator -->
        <.health_indicator health={@cluster_data.cluster_health} />
        
        <!-- Key metrics -->
        <.metrics 
          nodes={@cluster_data.nodes}
          stores={@cluster_data.stores}
          total_streams={@cluster_data.total_streams}
        />
        
        <!-- Quick summary -->
        <.summary_text 
          health={@cluster_data.cluster_health}
          nodes={@cluster_data.nodes}
          stores={@cluster_data.stores}
        />
      </div>

      <div class="widget-footer">
        <small class="last-updated">
          Updated: <%= Calendar.strftime(@last_updated, "%H:%M:%S") %>
        </small>
      </div>
    </div>
    """
  end

  # Component helpers

  defp health_indicator(assigns) do
    health_class = health_to_class(assigns.health)
    health_emoji = health_to_emoji(assigns.health)
    health_text = health_to_text(assigns.health)
    
    assigns = assign(assigns, :health_class, health_class)
    assigns = assign(assigns, :health_emoji, health_emoji) 
    assigns = assign(assigns, :health_text, health_text)
    
    ~H"""
    <div class={"health-indicator #{@health_class}"}>
      <span class="health-emoji"><%= @health_emoji %></span>
      <span class="health-text"><%= @health_text %></span>
    </div>
    """
  end

  defp metrics(assigns) do
    ex_esdb_nodes = Enum.count(assigns.nodes, & &1.is_ex_esdb)
    total_nodes = length(assigns.nodes)
    total_stores = length(assigns.stores)
    
    assigns = assign(assigns, :ex_esdb_nodes, ex_esdb_nodes)
    assigns = assign(assigns, :total_nodes, total_nodes)
    assigns = assign(assigns, :total_stores, total_stores)
    
    ~H"""
    <div class="metrics">
      <div class="metric">
        <span class="metric-value"><%= @total_nodes %></span>
        <span class="metric-label">Nodes</span>
      </div>
      <div class="metric">
        <span class="metric-value"><%= @ex_esdb_nodes %></span>
        <span class="metric-label">ExESDB</span>
      </div>
      <div class="metric">
        <span class="metric-value"><%= @total_stores %></span>
        <span class="metric-label">Stores</span>
      </div>
      <div class="metric">
        <span class="metric-value"><%= @total_streams %></span>
        <span class="metric-label">Streams</span>
      </div>
    </div>
    """
  end

  defp summary_text(assigns) do
    ex_esdb_count = Enum.count(assigns.nodes, & &1.is_ex_esdb)
    store_count = length(assigns.stores)
    
    summary = case assigns.health do
      :healthy -> 
        "Cluster is healthy with #{ex_esdb_count} ExESDB nodes and #{store_count} stores."
      :degraded -> 
        "Cluster is degraded. Check node connectivity."
      :unhealthy -> 
        "Cluster is unhealthy. Immediate attention required."
      :no_cluster -> 
        "No ExESDB cluster detected."
      :no_stores -> 
        "No event stores available."
      _ -> 
        "Cluster status unknown."
    end
    
    assigns = assign(assigns, :summary, summary)
    
    ~H"""
    <p class="summary-text"><%= @summary %></p>
    """
  end

  # Helper functions

  defp health_to_class(:healthy), do: "healthy"
  defp health_to_class(:degraded), do: "degraded"
  defp health_to_class(:unhealthy), do: "unhealthy"
  defp health_to_class(:no_cluster), do: "no-cluster"
  defp health_to_class(:no_stores), do: "no-stores"
  defp health_to_class(_), do: "unknown"

  defp health_to_emoji(:healthy), do: "✅"
  defp health_to_emoji(:degraded), do: "⚠️"
  defp health_to_emoji(:unhealthy), do: "❌"
  defp health_to_emoji(:no_cluster), do: "🚫"
  defp health_to_emoji(:no_stores), do: "📭"
  defp health_to_emoji(_), do: "❓"

  defp health_to_text(:healthy), do: "Healthy"
  defp health_to_text(:degraded), do: "Degraded"
  defp health_to_text(:unhealthy), do: "Unhealthy" 
  defp health_to_text(:no_cluster), do: "No Cluster"
  defp health_to_text(:no_stores), do: "No Stores"
  defp health_to_text(_), do: "Unknown"

end
