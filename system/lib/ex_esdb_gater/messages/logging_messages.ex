defmodule ExESDBGater.Messages.LoggingMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_logging PubSub instance.

  Handles log aggregation and distribution across the cluster.

  ## Common Topics
  - "application_logs" - Application-level log messages
  - "system_logs" - System-level log messages
  - "error_logs" - Error and exception logs
  - "audit_logs" - Audit trail logs
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_logging

  # Message payload structs

  @doc "Log entry payload"
  defmodule LogEntry do
    defstruct [
    :log_id,         # string - unique log identifier
    :level,          # :debug | :info | :warn | :error | :critical
    :message,        # string - log message
    :module,         # atom - module that generated the log
    :function,       # string - function that generated the log
    :line,           # integer - line number
    :node,           # atom - node where log originated
    :pid,            # pid - process that generated the log
    :metadata,       # map - additional log metadata
    :timestamp       # DateTime.t
  ]
  end

  @doc "Log aggregation summary payload"
  defmodule LogSummary do
    defstruct [
    :summary_id,     # string - unique summary identifier
    :time_period,    # string - time period of summary (e.g., "last_hour")
    :log_counts,     # map - count by log level
    :top_errors,     # [map] - most frequent errors
    :error_rate,     # float - errors per minute
    :nodes_reporting, # [atom] - nodes that reported logs
    :total_logs,     # integer - total log entries in period
    :timestamp       # DateTime.t
  ]
  end

  @doc "Log filtering rule payload"
  defmodule LogFilter do
    defstruct [
    :filter_id,      # string - unique filter identifier
    :filter_type,    # :level | :module | :pattern | :node
    :filter_value,   # any - filter criteria
    :action,         # :include | :exclude | :rate_limit
    :enabled,        # boolean - whether filter is active
    :created_by,     # string - who created the filter
    :metadata,       # map - additional filter context
    :timestamp       # DateTime.t
  ]
  end

  @doc "Log rotation event payload"
  defmodule LogRotation do
    defstruct [
    :rotation_id,    # string - unique rotation identifier
    :log_type,       # string - type of log being rotated
    :old_file,       # string - path to old log file
    :new_file,       # string - path to new log file
    :file_size,      # integer - size of rotated file
    :entries_count,  # integer - number of entries in rotated file
    :node,           # atom - node where rotation occurred
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a log entry"
  def broadcast_log_entry(topic, %LogEntry{} = payload) do
    secure_broadcast(topic, {:log_entry, payload})
  end

  @doc "Broadcast a log summary"
  def broadcast_log_summary(topic, %LogSummary{} = payload) do
    secure_broadcast(topic, {:log_summary, payload})
  end

  @doc "Broadcast a log filter update"
  def broadcast_log_filter(topic, %LogFilter{} = payload) do
    secure_broadcast(topic, {:log_filter_updated, payload})
  end

  @doc "Broadcast a log rotation event"
  def broadcast_log_rotation(topic, %LogRotation{} = payload) do
    secure_broadcast(topic, {:log_rotation, payload})
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

  @doc "Create a LogEntry payload with current timestamp"
  def log_entry(level, message, module, opts \\ []) do
    %LogEntry{
      log_id: Keyword.get(opts, :log_id, generate_log_id()),
      level: level,
      message: message,
      module: module,
      function: Keyword.get(opts, :function),
      line: Keyword.get(opts, :line),
      node: Keyword.get(opts, :node, Node.self()),
      pid: Keyword.get(opts, :pid, self()),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a LogSummary payload with current timestamp"
  def log_summary(time_period, log_counts, opts \\ []) do
    %LogSummary{
      summary_id: Keyword.get(opts, :summary_id, generate_summary_id()),
      time_period: time_period,
      log_counts: log_counts,
      top_errors: Keyword.get(opts, :top_errors, []),
      error_rate: Keyword.get(opts, :error_rate, 0.0),
      nodes_reporting: Keyword.get(opts, :nodes_reporting, [Node.self()]),
      total_logs: Keyword.get(opts, :total_logs, Enum.sum(Map.values(log_counts))),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a LogFilter payload with current timestamp"
  def log_filter(filter_type, filter_value, action, opts \\ []) do
    %LogFilter{
      filter_id: Keyword.get(opts, :filter_id, generate_filter_id()),
      filter_type: filter_type,
      filter_value: filter_value,
      action: action,
      enabled: Keyword.get(opts, :enabled, true),
      created_by: Keyword.get(opts, :created_by, "system"),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a LogRotation payload with current timestamp"
  def log_rotation(log_type, old_file, new_file, opts \\ []) do
    %LogRotation{
      rotation_id: Keyword.get(opts, :rotation_id, generate_rotation_id()),
      log_type: log_type,
      old_file: old_file,
      new_file: new_file,
      file_size: Keyword.get(opts, :file_size),
      entries_count: Keyword.get(opts, :entries_count),
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
  end

  # Private helper functions

  defp generate_log_id do
    "log_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_summary_id do
    "summary_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_filter_id do
    "filter_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_rotation_id do
    "rotation_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
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
