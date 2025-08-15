defmodule ExESDBGater.Messages.SecurityMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_security PubSub instance.

  Handles security events, authentication, authorization, and access violations.

  ## Common Topics
  - "auth_events" - Authentication and authorization events
  - "access_violations" - Unauthorized access attempts
  - "security_alerts" - Security-related alerts
  - "session_events" - Session management events
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_security

  # Message payload structs

  @doc "Authentication event payload"
  defmodule AuthEvent do
    defstruct [
    :user_id,        # string - user identifier
    :event_type,     # :login_success | :login_failure | :logout | :token_refresh
    :auth_method,    # :password | :token | :certificate | :oauth
    :source_ip,      # string - IP address of the request
    :user_agent,     # string - user agent string
    :node,           # atom - node where auth occurred
    :metadata,       # map - additional auth context
    :timestamp       # DateTime.t
  ]
  end

  @doc "Access violation payload"
  defmodule AccessViolation do
    defstruct [
    :user_id,        # string - user identifier (if known)
    :violation_type, # :unauthorized_access | :permission_denied | :rate_limit_exceeded | :invalid_token
    :resource,       # string - resource that was accessed
    :action,         # string - action that was attempted
    :source_ip,      # string - IP address of the request
    :severity,       # :low | :medium | :high | :critical
    :metadata,       # map - additional violation context
    :timestamp       # DateTime.t
  ]
  end

  @doc "Security alert payload"
  defmodule SecurityAlert do
    defstruct [
    :alert_type,     # :brute_force | :suspicious_activity | :policy_violation | :data_breach
    :severity,       # :low | :medium | :high | :critical
    :description,    # string - human-readable description
    :affected_users, # [string] - list of affected user IDs
    :source_ip,      # string - source IP (if applicable)
    :node,           # atom - node where alert was generated
    :metadata,       # map - additional alert context
    :timestamp       # DateTime.t
  ]
  end

  @doc "Session event payload"
  defmodule SessionEvent do
    defstruct [
    :session_id,     # string - session identifier
    :user_id,        # string - user identifier
    :event_type,     # :created | :destroyed | :expired | :invalidated
    :duration_ms,    # integer - session duration (for destroy events)
    :source_ip,      # string - IP address
    :node,           # atom - node where session event occurred
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast an authentication event"
  def broadcast_auth_event(topic, %AuthEvent{} = payload) do
    secure_broadcast(topic, {:auth_event, payload})
  end

  @doc "Broadcast an access violation"
  def broadcast_access_violation(topic, %AccessViolation{} = payload) do
    secure_broadcast(topic, {:access_violation, payload})
  end

  @doc "Broadcast a security alert"
  def broadcast_security_alert(topic, %SecurityAlert{} = payload) do
    secure_broadcast(topic, {:security_alert, payload})
  end

  @doc "Broadcast a session event"
  def broadcast_session_event(topic, %SessionEvent{} = payload) do
    secure_broadcast(topic, {:session_event, payload})
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

  @doc "Create an AuthEvent payload with current timestamp"
  def auth_event(user_id, event_type, auth_method, opts \\ []) do
    %AuthEvent{
      user_id: user_id,
      event_type: event_type,
      auth_method: auth_method,
      source_ip: Keyword.get(opts, :source_ip),
      user_agent: Keyword.get(opts, :user_agent),
      node: Keyword.get(opts, :node, Node.self()),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create an AccessViolation payload with current timestamp"
  def access_violation(violation_type, resource, action, opts \\ []) do
    %AccessViolation{
      user_id: Keyword.get(opts, :user_id),
      violation_type: violation_type,
      resource: resource,
      action: action,
      source_ip: Keyword.get(opts, :source_ip),
      severity: Keyword.get(opts, :severity, :medium),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a SecurityAlert payload with current timestamp"
  def security_alert(alert_type, severity, description, opts \\ []) do
    %SecurityAlert{
      alert_type: alert_type,
      severity: severity,
      description: description,
      affected_users: Keyword.get(opts, :affected_users, []),
      source_ip: Keyword.get(opts, :source_ip),
      node: Keyword.get(opts, :node, Node.self()),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a SessionEvent payload with current timestamp"
  def session_event(session_id, user_id, event_type, opts \\ []) do
    %SessionEvent{
      session_id: session_id,
      user_id: user_id,
      event_type: event_type,
      duration_ms: Keyword.get(opts, :duration_ms),
      source_ip: Keyword.get(opts, :source_ip),
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
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
