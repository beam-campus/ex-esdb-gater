defmodule ExESDBGater.Messages.SystemMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_system PubSub instance.

  Handles general system-level configuration and startup/shutdown events.

  ## Common Topics
  - "config" - System configuration changes
  - "lifecycle" - System startup/shutdown events  
  - "features" - Feature toggle changes

  ## Node Field Pattern
  All message structs include a `:node` field that tracks the originating node
  using `Node.self()` as the default value.
  """

  alias Phoenix.PubSub
  alias ExESDBGater.MessageHelpers

  @pubsub_instance :ex_esdb_system

  # Message payload structs

  defmodule SystemConfig do
    @moduledoc """
    System configuration change payload
    """
    defstruct [
      :component,      # atom - which component changed config
      :changes,        # map - what changed
      :previous_config, # map - previous configuration (optional)
      :timestamp,      # DateTime.t
      :changed_by,     # string - who/what triggered the change
      :node            # atom - node where config change originated
    ]
  end

  defmodule SystemLifecycle do
    @moduledoc """
    System startup/shutdown payload
    """
    defstruct [
      :event,          # :starting | :started | :stopping | :stopped
      :system_name,    # atom - name of the system
      :version,        # string - system version
      :node,           # atom - node where event occurred
      :timestamp       # DateTime.t
    ]
  end

  defmodule FeatureToggle do
    @moduledoc """
    Feature toggle change payload
    """
    defstruct [
      :feature,        # atom - feature name
      :enabled,        # boolean - new state
      :previous_state, # boolean - previous state
      :changed_by,     # string - who changed it
      :timestamp,      # DateTime.t
      :node            # atom - node where toggle was changed
    ]
  end

  # Broadcasting helpers

  @doc "Broadcast a system configuration change"
  def broadcast_system_config(topic, %SystemConfig{} = payload) do
    secure_broadcast(topic, {:system_config_changed, payload})
  end

  @doc "Broadcast a system lifecycle event"
  def broadcast_system_lifecycle(topic, %SystemLifecycle{} = payload) do
    secure_broadcast(topic, {:system_lifecycle_event, payload})
  end

  @doc "Broadcast a feature toggle change"
  def broadcast_feature_toggle(topic, %FeatureToggle{} = payload) do
    secure_broadcast(topic, {:feature_toggle_changed, payload})
  end

  # Generic secure broadcasting
  def secure_broadcast(topic, message) when is_binary(topic) do
    case get_secret_key() do
      {:ok, _secret} ->
        secured_message = add_security_signature(message)
        PubSub.broadcast(@pubsub_instance, topic, secured_message)
      
      {:error, :no_secret} ->
        require Logger
        Logger.warning("Broadcasting unsecured message - no SECRET_KEY_BASE configured")
        PubSub.broadcast(@pubsub_instance, topic, {:unsecured_message, message})
    end
  end

  @doc "Validate and extract a secure message"
  def validate_secure_message({:secure_message, signature, original_message}) do
    case get_secret_key() do
      {:ok, _secret} ->
        expected_signature = generate_signature(original_message)
        
        if :crypto.hash_equals(signature, expected_signature) do
          {:ok, original_message}
        else
          {:error, :invalid_signature}
        end
      
      {:error, :no_secret} ->
        {:error, :no_secret_configured}
    end
  end

  def validate_secure_message({:unsecured_message, original_message}) do
    case get_secret_key() do
      {:ok, _secret} ->
        {:error, :unsecured_message_rejected}
      
      {:error, :no_secret} ->
        require Logger
        Logger.warning("Accepting unsecured message - no SECRET_KEY_BASE configured")
        {:ok, original_message}
    end
  end

  def validate_secure_message(_), do: {:error, :invalid_format}

  # Helper functions for creating payload structs

  @doc "Create a SystemConfig payload with current timestamp"
  def system_config(component, changes, opts \\ []) do
    %SystemConfig{
      component: component,
      changes: changes,
      previous_config: Keyword.get(opts, :previous_config),
      timestamp: MessageHelpers.current_timestamp(),
      changed_by: Keyword.get(opts, :changed_by, "system"),
      node: MessageHelpers.get_node(opts)
    }
  end

  @doc "Create a SystemLifecycle payload with current timestamp"
  def system_lifecycle(event, system_name, version, opts \\ []) do
    %SystemLifecycle{
      event: event,
      system_name: system_name,
      version: version,
      node: MessageHelpers.get_node(opts),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create a FeatureToggle payload with current timestamp"
  def feature_toggle(feature, enabled, previous_state, changed_by, opts \\ []) do
    %FeatureToggle{
      feature: feature,
      enabled: enabled,
      previous_state: previous_state,
      changed_by: changed_by,
      timestamp: MessageHelpers.current_timestamp(),
      node: MessageHelpers.get_node(opts)
    }
  end

  # Message validation functions
  
  @doc "Validate a SystemConfig message"
  def validate_system_config(%SystemConfig{} = message) do
    MessageHelpers.validate_common(message, [:component, :changes])
  end
  
  @doc "Validate a SystemLifecycle message"
  def validate_system_lifecycle(%SystemLifecycle{} = message) do
    MessageHelpers.validate_common(message, [:event, :system_name, :version, :node])
  end
  
  @doc "Validate a FeatureToggle message"
  def validate_feature_toggle(%FeatureToggle{} = message) do
    MessageHelpers.validate_common(message, [:feature, :enabled, :changed_by, :node])
  end

  # Private security functions

  defp add_security_signature(message) do
    signature = generate_signature(message)
    {:secure_message, signature, message}
  end

  defp generate_signature(message) do
    {:ok, secret_key} = get_secret_key()
    message_binary = :erlang.term_to_binary(message)
    :crypto.mac(:hmac, :sha256, secret_key, message_binary)
  end

  defp get_secret_key do
    cond do
      secret = Application.get_env(:ex_esdb_gater, :secret_key_base) ->
        {:ok, secret}
      
      secret = System.get_env("SECRET_KEY_BASE") ->
        {:ok, secret}
      
      secret = Application.get_env(:phoenix, :secret_key_base) ->
        {:ok, secret}
      
      true ->
        {:error, :no_secret}
    end
  end
end
