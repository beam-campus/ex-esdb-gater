defmodule ExESDBGater.Dashboard.ClusterLive do
  @moduledoc """
  Main cluster dashboard LiveView component.
  
  Displays real-time cluster information including:
  - Connected nodes and their status
  - Available stores and statistics
  - Overall cluster health
  - Real-time updates via PubSub
  """
  use Phoenix.LiveView
  
  alias ExESDBGater.Dashboard
  alias ExESDBGater.Messages.{HealthMessages, LifecycleMessages, SystemMessages}
  
  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to structured message topics
    if connected?(socket) do
      # Subscribe to health updates
      Phoenix.PubSub.subscribe(:ex_esdb_health, "cluster_health")
      Phoenix.PubSub.subscribe(:ex_esdb_health, "node_health")
      
      # Subscribe to lifecycle events
      Phoenix.PubSub.subscribe(:ex_esdb_lifecycle, "cluster_membership")
      Phoenix.PubSub.subscribe(:ex_esdb_lifecycle, "node_lifecycle")
      
      # Subscribe to system events
      Phoenix.PubSub.subscribe(:ex_esdb_system, "lifecycle")
      
      # Set up periodic refresh as fallback
      :timer.send_interval(30_000, self(), :refresh_data)
    end
    
    # Load initial cluster data
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(:cluster_data, cluster_data)
      |> assign(:loading, false)
      |> assign(:last_updated, DateTime.utc_now())
      |> assign(:page_title, "Cluster Dashboard")
    
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    action = Map.get(params, "live_action", :cluster)
    {:noreply, assign(socket, :live_action, action)}
  end

  @impl true
  def handle_info(:refresh_data, socket) do
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(:cluster_data, cluster_data)
      |> assign(:last_updated, DateTime.utc_now())
    
    {:noreply, socket}
  end

  # Handle structured health messages
  @impl true
  def handle_info({:secure_message, signature, {:cluster_health_updated, _payload}} = message, socket) do
    case HealthMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:secure_message, signature, {:node_health_updated, _payload}} = message, socket) do
    case HealthMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  # Handle structured lifecycle messages
  @impl true
  def handle_info({:secure_message, signature, {:cluster_membership_changed, _payload}} = message, socket) do
    case LifecycleMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:secure_message, signature, {:node_lifecycle_event, _payload}} = message, socket) do
    case LifecycleMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  # Handle structured system messages
  @impl true
  def handle_info({:secure_message, signature, {:system_lifecycle_event, _payload}} = message, socket) do
    case SystemMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  # Handle unsecured messages (dev/test environments)
  @impl true
  def handle_info({:unsecured_message, {:cluster_health_updated, _payload}} = message, socket) do
    case HealthMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:unsecured_message, {:node_health_updated, _payload}} = message, socket) do
    case HealthMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:unsecured_message, {:cluster_membership_changed, _payload}} = message, socket) do
    case LifecycleMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:unsecured_message, {:node_lifecycle_event, _payload}} = message, socket) do
    case LifecycleMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:unsecured_message, {:system_lifecycle_event, _payload}} = message, socket) do
    case SystemMessages.validate_secure_message(message) do
      {:ok, _} -> handle_cluster_update(socket)
      {:error, _} -> {:noreply, socket}
    end
  end

  # Handle legacy messages during transition period
  @impl true
  def handle_info({:cluster_state_changed, _new_state}, socket) do
    handle_cluster_update(socket)
  end

  # Ignore unknown messages
  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Common cluster update handler
  defp handle_cluster_update(socket) do
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(:cluster_data, cluster_data)
      |> assign(:last_updated, DateTime.utc_now())
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    cluster_data = Dashboard.get_cluster_data()
    
    socket = 
      socket
      |> assign(:cluster_data, cluster_data)
      |> assign(:last_updated, DateTime.utc_now())
      |> put_flash(:info, "Cluster data refreshed")
    
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="cluster-dashboard">
      <.header>
        <:title>ExESDB Cluster Dashboard</:title>
        <:subtitle>Real-time cluster monitoring and management</:subtitle>
        <:actions>
          <button 
            type="button" 
            phx-click="refresh"
            class="refresh-button"
            title="Refresh cluster data"
          >
            🔄 Refresh
          </button>
        </:actions>
      </.header>

      <div class="dashboard-grid">
        <!-- Cluster Health Overview -->
        <.cluster_health_card cluster_health={@cluster_data.cluster_health} />
        
        <!-- Quick Stats -->
        <.stats_cards 
          nodes={@cluster_data.nodes}
          stores={@cluster_data.stores}
          total_streams={@cluster_data.total_streams}
        />
        
        <!-- Nodes Section -->
        <.nodes_section nodes={@cluster_data.nodes} />
        
        <!-- Stores Section -->
        <.stores_section stores={@cluster_data.stores} />
      </div>

      <div class="dashboard-footer">
        <p class="last-updated">
          Last updated: <%= Calendar.strftime(@last_updated, "%H:%M:%S UTC") %>
        </p>
      </div>
    </div>
    """
  end

  # Component functions

  defp header(assigns) do
    ~H"""
    <header class="dashboard-header">
      <div class="title-section">
        <h1><%= render_slot(@title) %></h1>
        <p class="subtitle"><%= render_slot(@subtitle) %></p>
      </div>
      <div class="actions-section">
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  defp cluster_health_card(assigns) do
    health_class = health_to_class(assigns.cluster_health)
    health_text = health_to_text(assigns.cluster_health)
    health_emoji = health_to_emoji(assigns.cluster_health)
    
    assigns = assign(assigns, :health_class, health_class)
    assigns = assign(assigns, :health_text, health_text)
    assigns = assign(assigns, :health_emoji, health_emoji)
    
    ~H"""
    <div class={"card health-card #{@health_class}"}>
      <div class="card-header">
        <h3>Cluster Health</h3>
      </div>
      <div class="card-body">
        <div class="health-status">
          <span class="health-emoji"><%= @health_emoji %></span>
          <span class="health-text"><%= @health_text %></span>
        </div>
      </div>
    </div>
    """
  end

  defp stats_cards(assigns) do
    ex_esdb_nodes = Enum.count(assigns.nodes, & &1.is_ex_esdb)
    total_nodes = length(assigns.nodes)
    total_stores = length(assigns.stores)
    
    assigns = assign(assigns, :ex_esdb_nodes, ex_esdb_nodes)
    assigns = assign(assigns, :total_nodes, total_nodes)  
    assigns = assign(assigns, :total_stores, total_stores)
    
    ~H"""
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-value"><%= @total_nodes %></div>
        <div class="stat-label">Total Nodes</div>
      </div>
      <div class="stat-card">
        <div class="stat-value"><%= @ex_esdb_nodes %></div>
        <div class="stat-label">ExESDB Nodes</div>
      </div>
      <div class="stat-card">
        <div class="stat-value"><%= @total_stores %></div>
        <div class="stat-label">Stores</div>
      </div>
      <div class="stat-card">
        <div class="stat-value"><%= @total_streams %></div>
        <div class="stat-label">Total Streams</div>
      </div>
    </div>
    """
  end

  defp nodes_section(assigns) do
    ~H"""
    <div class="section nodes-section">
      <div class="section-header">
        <h3>Cluster Nodes</h3>
        <span class="node-count"><%= length(@nodes) %> nodes</span>
      </div>
      <div class="nodes-grid">
        <.node_card :for={node <- @nodes} node={node} />
      </div>
    </div>
    """
  end

  defp node_card(assigns) do
    node_class = node_status_class(assigns.node.status, assigns.node.is_ex_esdb)
    node_emoji = node_status_emoji(assigns.node.status, assigns.node.is_ex_esdb)
    uptime_text = format_uptime(assigns.node.uptime)
    
    assigns = assign(assigns, :node_class, node_class)
    assigns = assign(assigns, :node_emoji, node_emoji)
    assigns = assign(assigns, :uptime_text, uptime_text)
    
    ~H"""
    <div class={"card node-card #{@node_class}"}>
      <div class="node-header">
        <span class="node-emoji"><%= @node_emoji %></span>
        <span class="node-name"><%= @node.name %></span>
      </div>
      <div class="node-details">
        <div class="node-type">
          <%= if @node.is_ex_esdb, do: "ExESDB Node", else: "Gater Node" %>
        </div>
        <div class="node-uptime">Uptime: <%= @uptime_text %></div>
      </div>
    </div>
    """
  end

  defp stores_section(assigns) do
    ~H"""
    <div class="section stores-section">
      <div class="section-header">
        <h3>Event Stores</h3>
        <span class="store-count"><%= length(@stores) %> stores</span>
      </div>
      <%= if length(@stores) > 0 do %>
        <div class="stores-grid">
          <.store_card :for={store <- @stores} store={store} />
        </div>
      <% else %>
        <div class="empty-state">
          <p>No stores available. Ensure ExESDB nodes are connected and running.</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp store_card(assigns) do
    ~H"""
    <div class="card store-card">
      <div class="store-header">
        <h4><%= @store.name %></h4>
        <span class="store-status">
          <%= if @store.status == :healthy, do: "✅", else: "⚠️" %>
        </span>
      </div>
      <div class="store-stats">
        <div class="store-stat">
          <span class="stat-value"><%= @store.stream_count %></span>
          <span class="stat-label">Streams</span>
        </div>
        <div class="store-stat">
          <span class="stat-value"><%= @store.subscription_count %></span>
          <span class="stat-label">Subscriptions</span>
        </div>
        <div class="store-stat">
          <span class="stat-value"><%= length(@store.nodes) %></span>
          <span class="stat-label">Nodes</span>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp health_to_class(:healthy), do: "healthy"
  defp health_to_class(:degraded), do: "degraded"  
  defp health_to_class(:unhealthy), do: "unhealthy"
  defp health_to_class(:no_cluster), do: "no-cluster"
  defp health_to_class(:no_stores), do: "no-stores"
  defp health_to_class(_), do: "unknown"

  defp health_to_text(:healthy), do: "Healthy"
  defp health_to_text(:degraded), do: "Degraded"
  defp health_to_text(:unhealthy), do: "Unhealthy"
  defp health_to_text(:no_cluster), do: "No Cluster"
  defp health_to_text(:no_stores), do: "No Stores"
  defp health_to_text(_), do: "Unknown"

  defp health_to_emoji(:healthy), do: "✅"
  defp health_to_emoji(:degraded), do: "⚠️"
  defp health_to_emoji(:unhealthy), do: "❌"
  defp health_to_emoji(:no_cluster), do: "🚫"
  defp health_to_emoji(:no_stores), do: "📭"
  defp health_to_emoji(_), do: "❓"

  defp node_status_class(:self, _), do: "self-node"
  defp node_status_class(:connected, true), do: "ex-esdb-node connected"
  defp node_status_class(:connected, false), do: "gater-node connected"
  defp node_status_class(_, _), do: "disconnected"

  defp node_status_emoji(:self, _), do: "🏠"
  defp node_status_emoji(:connected, true), do: "🗄️"
  defp node_status_emoji(:connected, false), do: "🌐"
  defp node_status_emoji(_, _), do: "❌"

  defp format_uptime(uptime_ms) when is_integer(uptime_ms) and uptime_ms > 0 do
    seconds = div(uptime_ms, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)
    
    cond do
      days > 0 -> "#{days}d #{rem(hours, 24)}h"
      hours > 0 -> "#{hours}h #{rem(minutes, 60)}m"
      minutes > 0 -> "#{minutes}m #{rem(seconds, 60)}s"
      true -> "#{seconds}s"
    end
  end
  defp format_uptime(_), do: "Unknown"

  defp pubsub_server do
    Application.get_env(:phoenix_pubsub, :name, ExESDBGater.PubSub)
  end
end
