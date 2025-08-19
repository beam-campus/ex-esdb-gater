defmodule ExESDBGater.Messages.AlertMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_alerts PubSub instance.

  Handles critical alerts and notifications that require immediate attention.

  ## Common Topics
  - "critical" - Critical system alerts
  - "warnings" - Warning-level alerts
  - "notifications" - General notifications
  - "escalations" - Alert escalations
  """

  alias Phoenix.PubSub

  alias ExESDBGater.MessageHelpers

  @pubsub_instance :ex_esdb_alerts

  # Message payload structs

  defmodule SystemAlert do
    @moduledoc """
    System alert payload
    """
    defstruct [
      # string - unique alert identifier
      :alert_id,
      # :info | :warning | :error | :critical
      :severity,
      # :system | :performance | :security | :data | :network
      :category,
      # string - short alert title
      :title,
      # string - detailed alert description
      :description,
      # string - what generated the alert
      :source,
      # atom - node where alert originated
      :node,
      # map - additional alert context
      :metadata,
      # boolean - whether alert requires acknowledgment
      :requires_ack,
      # DateTime.t
      :timestamp
    ]
  end

  defmodule AlertAck do
    @moduledoc """
    Alert acknowledgment payload
    """
    defstruct [
      # string - alert being acknowledged
      :alert_id,
      # string - who acknowledged it
      :ack_by,
      # string - acknowledgment note
      :ack_note,
      # string - how the alert was resolved
      :resolution,
      # DateTime.t - when acknowledged
      :ack_timestamp,
      # DateTime.t
      :timestamp
    ]
  end

  defmodule AlertEscalation do
    @moduledoc """
    Alert escalation payload
    """
    defstruct [
      # string - alert being escalated
      :alert_id,
      # :level1 | :level2 | :level3
      :from_level,
      # :level1 | :level2 | :level3
      :to_level,
      # string - why it was escalated
      :escalation_reason,
      # string - who escalated it (or "system")
      :escalated_by,
      # [string] - contacts to notify
      :notify_contacts,
      # DateTime.t
      :timestamp
    ]
  end

  defmodule NotificationStatus do
    @moduledoc """
    Notification delivery status payload
    """
    defstruct [
      # string - related alert
      :alert_id,
      # :email | :sms | :webhook | :push
      :delivery_method,
      # string - who was notified
      :recipient,
      # :sent | :delivered | :failed | :bounced
      :status,
      # string - failure reason (if failed)
      :error_reason,
      # integer - delivery attempts made
      :attempts,
      # DateTime.t
      :timestamp
    ]
  end

  # Broadcasting helpers

  @doc "Broadcast a system alert"
  def broadcast_system_alert(topic, %SystemAlert{} = payload) do
    secure_broadcast(topic, {:system_alert, payload})
  end

  @doc "Broadcast an alert acknowledgment"
  def broadcast_alert_ack(topic, %AlertAck{} = payload) do
    secure_broadcast(topic, {:alert_acknowledged, payload})
  end

  @doc """
    Broadcast an alert escalation
  """
  def broadcast_alert_escalation(topic, %AlertEscalation{} = payload) do
    secure_broadcast(topic, {:alert_escalated, payload})
  end

  @doc "Broadcast a notification delivery status"
  def broadcast_notification_status(topic, %NotificationStatus{} = payload) do
    secure_broadcast(topic, {:notification_status, payload})
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

  @doc "Create a SystemAlert payload with current timestamp"
  def system_alert(severity, category, title, description, source, opts \\ []) do
    %SystemAlert{
      alert_id: Keyword.get(opts, :alert_id, generate_alert_id()),
      severity: severity,
      category: category,
      title: title,
      description: description,
      source: source,
      node: MessageHelpers.get_node(opts),
      metadata: Keyword.get(opts, :metadata, %{}),
      requires_ack: Keyword.get(opts, :requires_ack, severity in [:error, :critical]),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create an AlertAck payload with current timestamp"
  def alert_ack(alert_id, ack_by, opts \\ []) do
    %AlertAck{
      alert_id: alert_id,
      ack_by: ack_by,
      ack_note: Keyword.get(opts, :ack_note),
      resolution: Keyword.get(opts, :resolution),
      ack_timestamp: Keyword.get(opts, :ack_timestamp, MessageHelpers.current_timestamp()),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create an AlertEscalation payload with current timestamp"
  def alert_escalation(alert_id, from_level, to_level, escalation_reason, opts \\ []) do
    %AlertEscalation{
      alert_id: alert_id,
      from_level: from_level,
      to_level: to_level,
      escalation_reason: escalation_reason,
      escalated_by: Keyword.get(opts, :escalated_by, "system"),
      notify_contacts: Keyword.get(opts, :notify_contacts, []),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  @doc "Create a NotificationStatus payload with current timestamp"
  def notification_status(alert_id, delivery_method, recipient, status, opts \\ []) do
    %NotificationStatus{
      alert_id: alert_id,
      delivery_method: delivery_method,
      recipient: recipient,
      status: status,
      error_reason: Keyword.get(opts, :error_reason),
      attempts: Keyword.get(opts, :attempts, 1),
      timestamp: MessageHelpers.current_timestamp()
    }
  end

  # Private helper functions

  defp generate_alert_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
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
