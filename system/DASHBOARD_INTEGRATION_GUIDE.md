# ExESDBGater Dashboard Integration Guide

This guide shows how to integrate the ExESDBGater cluster dashboard into your Phoenix application.

## Overview

The ExESDBGater dashboard provides real-time monitoring of your ExESDB cluster including:
- Node connectivity and health
- Store statistics and metrics  
- Real-time updates via Phoenix.PubSub
- Composable components for flexible integration

## Prerequisites

Your Phoenix application needs:

```elixir
# mix.exs
defp deps do
  [
    {:ex_esdb_gater, "~> 0.3.5"},
    {:phoenix_live_view, "~> 1.0"},
    {:phoenix_html, "~> 4.0"},
    {:jason, "~> 1.2"}
  ]
end
```

## Quick Start

### 1. Add ExESDBGater to your supervision tree

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    MyAppWeb.Endpoint,
    {Phoenix.PubSub, name: MyApp.PubSub},
    
    # Add ExESDBGater system
    {ExESDBGater.System, [
      # Your cluster configuration
    ]},
    
    # Your other processes...
  ]
  
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

### 2. Configure PubSub

Ensure Phoenix.PubSub is configured and ExESDBGater can use it:

```elixir
# config/config.exs
config :phoenix_pubsub, :name, MyApp.PubSub
```

### 3. Add dashboard routes

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import ExESDBGater.Dashboard
  
  # ... other pipelines ...
  
  scope "/admin", MyAppWeb do
    pipe_through :browser
    
    # Add dashboard routes
    dashboard_routes()
  end
end
```

### 4. Visit your dashboard

Navigate to `/admin/cluster` in your application to see the dashboard.

## Advanced Integration Options

### Option 1: Full Dashboard LiveView

Mount the complete dashboard as a LiveView:

```elixir
# In your router
live "/cluster", ExESDBGater.Dashboard.ClusterLive
```

### Option 2: Embedded Status Widget

Embed the compact status widget in existing views:

```elixir
# In your existing LiveView
defmodule MyAppWeb.SomeLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ex_esdb_gater:cluster")
    end
    
    {:ok, socket}
  end
  
  # Forward cluster updates to the component
  def handle_info({:cluster_state_changed, _state}, socket) do
    send_update(ExESDBGater.Dashboard.ClusterStatus, id: "cluster-status")
    {:noreply, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div>
      <!-- Your existing content -->
      
      <.live_component 
        module={ExESDBGater.Dashboard.ClusterStatus} 
        id="cluster-status" 
      />
    </div>
    """
  end
end
```

### Option 3: Custom Integration

Use the Dashboard module directly for custom implementations:

```elixir
defmodule MyAppWeb.CustomLive do
  use Phoenix.LiveView
  alias ExESDBGater.Dashboard
  
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "ex_esdb_gater:cluster")
    end
    
    cluster_data = Dashboard.get_cluster_data()
    {:ok, assign(socket, :cluster_data, cluster_data)}
  end
  
  def handle_info({:cluster_state_changed, _state}, socket) do
    cluster_data = Dashboard.get_cluster_data()
    {:noreply, assign(socket, :cluster_data, cluster_data)}
  end
  
  def render(assigns) do
    ~H"""
    <div>
      <h2>My Custom Cluster View</h2>
      <p>Cluster Health: <%= @cluster_data.cluster_health %></p>
      <p>Total Nodes: <%= length(@cluster_data.nodes) %></p>
      <p>Total Stores: <%= length(@cluster_data.stores) %></p>
    </div>
    """
  end
end
```

## Styling the Dashboard

The dashboard uses semantic CSS classes that you can style:

```css
/* Basic dashboard styling */
.cluster-dashboard {
  /* Main dashboard container */
}

.dashboard-header {
  /* Header with title and actions */
}

.health-indicator.healthy {
  color: #10b981; /* Green */
}

.health-indicator.degraded {
  color: #f59e0b; /* Yellow */
}

.health-indicator.unhealthy {
  color: #ef4444; /* Red */
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.nodes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
}

.stores-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

/* Widget styling for embedded components */
.cluster-status-widget {
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
  background: white;
}

.widget-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.metrics {
  display: flex;
  gap: 1rem;
  margin: 1rem 0;
}

.metric {
  text-align: center;
}

.metric-value {
  display: block;
  font-size: 1.5rem;
  font-weight: bold;
}

.metric-label {
  display: block;
  font-size: 0.875rem;
  color: #6b7280;
}
```

## API Reference

### ExESDBGater.Dashboard

Main module providing dashboard functionality.

#### Functions

- `get_cluster_data/0` - Returns comprehensive cluster information
- `get_cluster_nodes/0` - Returns list of cluster nodes with status
- `get_cluster_stores/0` - Returns list of stores with statistics
- `cluster_live_component/0` - Returns the main dashboard LiveView module
- `cluster_status_component/0` - Returns the status widget module

#### Macros

- `dashboard_routes/0` - Adds standard dashboard routes to Phoenix router

### ExESDBGater.Dashboard.ClusterLive

Full-featured dashboard LiveView with:
- Real-time cluster monitoring
- Node status display
- Store statistics
- Health indicators
- Automatic refresh

### ExESDBGater.Dashboard.ClusterStatus

Compact status widget LiveComponent with:
- Cluster health indicator
- Key metrics summary
- Real-time updates
- Embeddable in any LiveView

## Real-time Updates

The dashboard automatically receives real-time updates via Phoenix.PubSub when:
- Nodes connect or disconnect
- Cluster health changes
- Store status changes

No manual refresh required - the UI updates automatically.

## Troubleshooting

### Dashboard not updating

1. Check that Phoenix.PubSub is configured:
   ```elixir
   config :phoenix_pubsub, :name, MyApp.PubSub
   ```

2. Verify ExESDBGater.System is in your supervision tree

3. Check browser console for JavaScript errors

### No cluster data showing

1. Ensure ExESDB nodes are connected and running
2. Verify libcluster configuration is correct
3. Check that stores are properly registered

### Styling issues

1. Add basic CSS styles (see styling section above)
2. Check that CSS classes are not conflicting with existing styles
3. Use browser dev tools to inspect component structure

## Example Applications

### Simple Admin Interface

```elixir
# lib/my_app_web/live/admin_live.ex
defmodule MyAppWeb.AdminLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class="admin-dashboard">
      <h1>System Administration</h1>
      
      <!-- Embedded cluster status -->
      <.live_component 
        module={ExESDBGater.Dashboard.ClusterStatus} 
        id="cluster-status" 
      />
      
      <!-- Other admin components -->
    </div>
    """
  end
end
```

### Monitoring Dashboard

```elixir
# lib/my_app_web/live/monitoring_live.ex
defmodule MyAppWeb.MonitoringLive do  
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:page_title, "System Monitoring")
    
    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class="monitoring-dashboard">
      <!-- Full cluster dashboard -->
      <.live_component 
        module={ExESDBGater.Dashboard.ClusterLive} 
        id="cluster-dashboard" 
      />
    </div>
    """
  end
end
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the ExESDBGater documentation
3. Open an issue on the GitHub repository

---

**Next Steps**: Try integrating the dashboard into your application and customize the styling to match your design system.
