defmodule ExESDBGater.PubSubSystem do
  @moduledoc """
  Supervisor for all PubSub instances used by ExESDBGater.
  """
  use Supervisor

  alias ExESDBGater.PubSubManager

  @pubsub_instances [
    :ex_esdb_events,      # Core event data
    :ex_esdb_system,      # General system events
    :ex_esdb_logging,     # Log aggregation
    :ex_esdb_health,      # Health monitoring
    :ex_esdb_metrics,     # Performance metrics
    :ex_esdb_security,    # Security events (auth, access violations)
    :ex_esdb_audit,       # Audit trail (compliance, who did what)
    :ex_esdb_alerts,      # Critical alerts and notifications
    :ex_esdb_diagnostics, # Deep diagnostic information
    :ex_esdb_lifecycle    # Process lifecycle events
  ]

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    children =
      for name <- @pubsub_instances do
        PubSubManager.maybe_child_spec(name)
      end
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
