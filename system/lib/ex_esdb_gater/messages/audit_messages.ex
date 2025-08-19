defmodule ExESDBGater.Messages.AuditMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_audit PubSub instance.

  Handles audit trail events for compliance and tracking who did what.

  ## Common Topics
  - "data_changes" - Data modification events
  - "admin_actions" - Administrative actions
  - "access_logs" - Resource access logging
  - "compliance" - Compliance-related events
  """

  alias Phoenix.PubSub
  alias ExESDBGater.MessageHelpers

  @pubsub_instance :ex_esdb_audit

  # Message payload structs

  defmodule DataChange do
    @moduledoc """
    Data change audit event payload
    """
    defstruct [
    :user_id,        # string - user who made the change
    :resource_type,  # string - type of resource changed
    :resource_id,    # string - identifier of the resource
    :action,         # :create | :update | :delete | :read
    :changes,        # map - what changed (before/after)
    :metadata,       # map - additional context
    :source_ip,      # string - IP address of the request
    :node,           # atom - node where change occurred
    :timestamp       # DateTime.t
  ]
  end

  defmodule AdminAction do
    @moduledoc """
    Administrative action audit event payload
    """
    defstruct [
    :admin_user_id,  # string - administrator who performed action
    :action_type,    # :user_created | :user_deleted | :permissions_changed | :config_updated
    :target_resource, # string - what was acted upon
    :details,        # map - action details
    :justification,  # string - reason for the action
    :source_ip,      # string - IP address
    :node,           # atom - node where action occurred
    :timestamp       # DateTime.t
  ]
  end

  defmodule AccessLog do
    @moduledoc """
    Access log audit event payload
    """
    defstruct [
    :user_id,        # string - user who accessed resource
    :resource_type,  # string - type of resource accessed
    :resource_id,    # string - identifier of the resource
    :action,         # string - action performed
    :success,        # boolean - whether access was successful
    :duration_ms,    # integer - how long the operation took
    :source_ip,      # string - IP address
    :user_agent,     # string - user agent
    :node,           # atom - node where access occurred
    :timestamp       # DateTime.t
  ]
  end

  defmodule ComplianceEvent do
    @moduledoc """
    Compliance event audit payload
    """
    defstruct [
    :event_type,     # :data_retention | :data_export | :data_deletion | :policy_violation
    :compliance_rule, # string - which rule this relates to
    :affected_data,  # map - description of affected data
    :action_taken,   # string - what action was taken
    :user_id,        # string - user involved (if any)
    :automated,      # boolean - whether this was automated
    :metadata,       # map - additional compliance context
    :node,           # atom - node where event occurred
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a data change audit event"
  def broadcast_data_change(topic, %DataChange{} = payload) do
    secure_broadcast(topic, {:data_change, payload})
  end

  @doc "Broadcast an administrative action audit event"
  def broadcast_admin_action(topic, %AdminAction{} = payload) do
    secure_broadcast(topic, {:admin_action, payload})
  end

  @doc "Broadcast an access log audit event"
  def broadcast_access_log(topic, %AccessLog{} = payload) do
    secure_broadcast(topic, {:access_log, payload})
  end

  @doc "Broadcast a compliance event"
  def broadcast_compliance_event(topic, %ComplianceEvent{} = payload) do
    secure_broadcast(topic, {:compliance_event, payload})
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

  @doc "Create a DataChange payload with current timestamp"
  def data_change(user_id, resource_type, resource_id, action, opts \\ []) do
    %DataChange{
      user_id: user_id,
      resource_type: resource_type,
      resource_id: resource_id,
      action: action,
      changes: Keyword.get(opts, :changes, %{}),
      metadata: Keyword.get(opts, :metadata, %{}),
      source_ip: Keyword.get(opts, :source_ip),
      node: MessageHelpers.get_node(opts),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create an AdminAction payload with current timestamp"
  def admin_action(admin_user_id, action_type, target_resource, opts \\ []) do
    %AdminAction{
      admin_user_id: admin_user_id,
      action_type: action_type,
      target_resource: target_resource,
      details: Keyword.get(opts, :details, %{}),
      justification: Keyword.get(opts, :justification),
      source_ip: Keyword.get(opts, :source_ip),
      node: MessageHelpers.get_node(opts),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create an AccessLog payload with current timestamp"
  def access_log(user_id, resource_type, resource_id, action, success, opts \\ []) do
    %AccessLog{
      user_id: user_id,
      resource_type: resource_type,
      resource_id: resource_id,
      action: action,
      success: success,
      duration_ms: Keyword.get(opts, :duration_ms),
      source_ip: Keyword.get(opts, :source_ip),
      user_agent: Keyword.get(opts, :user_agent),
      node: MessageHelpers.get_node(opts),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create a ComplianceEvent payload with current timestamp"
  def compliance_event(event_type, compliance_rule, affected_data, action_taken, opts \\ []) do
    %ComplianceEvent{
      event_type: event_type,
      compliance_rule: compliance_rule,
      affected_data: affected_data,
      action_taken: action_taken,
      user_id: Keyword.get(opts, :user_id),
      automated: Keyword.get(opts, :automated, false),
      metadata: Keyword.get(opts, :metadata, %{}),
      node: MessageHelpers.get_node(opts),
      timestamp: MessageHelpers.current_timestamp()
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
