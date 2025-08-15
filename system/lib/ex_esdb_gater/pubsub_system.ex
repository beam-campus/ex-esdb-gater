defmodule ExESDBGater.PubSubSystem do
  @moduledoc """
  Supervisor for all PubSub instances used by ExESDBGater.
  
  This supervisor is designed to be a singleton per node - it manages
  global PubSub instances that are shared across all ExESDB systems
  running on the same node.
  
  Multiple ExESDB systems can safely attempt to start this supervisor;
  if it's already running, the start_link call will return {:ok, pid}
  with the existing supervisor's pid rather than failing.
  
  This enables umbrella applications and multi-store setups where
  multiple ExESDB.System instances need to share the same PubSub
  infrastructure.
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

    case Supervisor.start_link(__MODULE__, opts, name: name) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        # PubSubSystem is designed to be a singleton - if it's already started,
        # that's exactly what we want. Return success with the existing pid.
        {:ok, pid}
      {:error, reason} ->
        {:error, reason}
    end
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
