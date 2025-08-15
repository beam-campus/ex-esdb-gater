defmodule ExESDBGater.Messages do
  @moduledoc """
  Main module providing access to all ExESDBGater message definitions and helpers.

  This module serves as a central entry point for all PubSub message types
  used throughout the ExESDBGater system.

  ## Message Modules

  Each PubSub instance has its own dedicated message module:

  - `SystemMessages` - General system configuration and lifecycle events (`:ex_esdb_system`)
  - `HealthMessages` - Health monitoring and status checks (`:ex_esdb_health`) 
  - `MetricsMessages` - Performance metrics and measurements (`:ex_esdb_metrics`)
  - `LifecycleMessages` - Process and node lifecycle events (`:ex_esdb_lifecycle`)
  - `SecurityMessages` - Security events and access control (`:ex_esdb_security`)
  - `AuditMessages` - Audit trail and compliance events (`:ex_esdb_audit`)
  - `AlertMessages` - Critical alerts and notifications (`:ex_esdb_alerts`)
  - `DiagnosticsMessages` - Deep diagnostic and debugging info (`:ex_esdb_diagnostics`)
  - `LoggingMessages` - Log aggregation and distribution (`:ex_esdb_logging`)

  ## Usage Examples

      # Using system messages
      alias ExESDBGater.Messages.SystemMessages
      
      # Create and broadcast a config change
      payload = SystemMessages.system_config(:database, %{pool_size: 10})
      SystemMessages.broadcast_system_config("config", payload)

      # Subscribe to health updates
      Phoenix.PubSub.subscribe(:ex_esdb_health, "node_health")
      
      # Validate received messages - using pattern matching
      def handle_info({:secure_message, _sig, {:node_health_updated, _payload}} = message, state) do
        case ExESDBGater.Messages.HealthMessages.validate_secure_message(message) do
          {:ok, {:node_health_updated, payload}} ->
            handle_health_update(payload, state)
          {:error, _reason} ->
            {:noreply, state}
        end
      end
      
      def handle_info(_message, state), do: {:noreply, state}

  ## Security

  All message modules include HMAC-based security using SECRET_KEY_BASE to prevent
  unauthorized messages from entering the system. Messages are automatically signed
  when broadcast and can be validated by receivers.
  """

  # Convenient aliases for all message modules
  alias ExESDBGater.Messages.SystemMessages
  alias ExESDBGater.Messages.HealthMessages  
  alias ExESDBGater.Messages.MetricsMessages
  alias ExESDBGater.Messages.LifecycleMessages
  alias ExESDBGater.Messages.SecurityMessages
  alias ExESDBGater.Messages.AuditMessages
  alias ExESDBGater.Messages.AlertMessages
  alias ExESDBGater.Messages.DiagnosticsMessages
  alias ExESDBGater.Messages.LoggingMessages

  @doc """
  Returns a map of PubSub instance atoms to their corresponding message modules.
  
  Useful for dynamic message handling or routing.
  """
  def instance_to_module_map do
    %{
      :ex_esdb_system => SystemMessages,
      :ex_esdb_health => HealthMessages,
      :ex_esdb_metrics => MetricsMessages,
      :ex_esdb_lifecycle => LifecycleMessages,
      :ex_esdb_security => SecurityMessages,
      :ex_esdb_audit => AuditMessages,
      :ex_esdb_alerts => AlertMessages,
      :ex_esdb_diagnostics => DiagnosticsMessages,
      :ex_esdb_logging => LoggingMessages
    }
  end

  @doc """
  Returns the message module for a given PubSub instance.
  
  ## Examples
  
      iex> ExESDBGater.Messages.module_for_instance(:ex_esdb_health)
      ExESDBGater.Messages.HealthMessages
      
      iex> ExESDBGater.Messages.module_for_instance(:invalid)
      nil
  """
  def module_for_instance(instance) do
    Map.get(instance_to_module_map(), instance)
  end

  @doc """
  Validates a message using the appropriate module for the given PubSub instance.
  
  ## Examples
  
      iex> ExESDBGater.Messages.validate_message(:ex_esdb_health, message)
      {:ok, {:node_health_updated, payload}}
  """
  def validate_message(instance, message) do
    case module_for_instance(instance) do
      nil -> {:error, :unknown_instance}
      module -> module.validate_secure_message(message)
    end
  end

  @doc """
  Returns a list of all supported PubSub instances.
  """
  def supported_instances do
    Map.keys(instance_to_module_map())
  end

  @doc """
  Returns a list of all message modules.
  """
  def all_modules do
    Map.values(instance_to_module_map())
  end
end
