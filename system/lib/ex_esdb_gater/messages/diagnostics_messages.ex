defmodule ExESDBGater.Messages.DiagnosticsMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_diagnostics PubSub instance.

  Handles deep diagnostic information for debugging and system analysis.

  ## Common Topics
  - "debug_traces" - Debug trace information
  - "performance_analysis" - Performance diagnostic data
  - "system_state" - System state snapshots
  - "error_analysis" - Error diagnostic information
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_diagnostics

  # Message payload structs

  @doc "Debug trace payload"
  defmodule DebugTrace do
    defstruct [
    :trace_id,       # string - unique trace identifier
    :component,      # atom - component being traced
    :operation,      # string - operation being performed
    :trace_data,     # map - trace-specific data
    :stack_trace,    # [string] - stack trace (if applicable)
    :duration_ms,    # integer - operation duration
    :node,           # atom - node where trace occurred
    :metadata,       # map - additional trace context
    :timestamp       # DateTime.t
  ]
  end

  @doc "Performance analysis payload"
  defmodule PerformanceAnalysis do
    defstruct [
    :analysis_id,    # string - unique analysis identifier
    :component,      # atom - component being analyzed
    :analysis_type,  # :bottleneck | :memory_leak | :cpu_hotspot | :io_analysis
    :findings,       # map - analysis results
    :recommendations, # [string] - performance recommendations
    :severity,       # :low | :medium | :high | :critical
    :node,           # atom - node where analysis was performed
    :timestamp       # DateTime.t
  ]
  end

  @doc "System state snapshot payload"
  defmodule SystemState do
    defstruct [
    :snapshot_id,    # string - unique snapshot identifier
    :snapshot_type,  # :full | :partial | :process_tree | :memory_dump
    :state_data,     # map - system state information
    :process_count,  # integer - number of processes
    :memory_usage,   # integer - memory usage in bytes
    :node,           # atom - node where snapshot was taken
    :trigger_reason, # string - why snapshot was taken
    :timestamp       # DateTime.t
  ]
  end

  @doc "Error analysis payload"
  defmodule ErrorAnalysis do
    defstruct [
    :error_id,       # string - unique error identifier
    :error_type,     # atom - type of error
    :error_message,  # string - error message
    :stack_trace,    # [string] - stack trace
    :context,        # map - error context
    :frequency,      # integer - how often this error occurs
    :first_seen,     # DateTime.t - when first seen
    :last_seen,      # DateTime.t - when last seen
    :node,           # atom - node where error occurred
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a debug trace"
  def broadcast_debug_trace(topic, %DebugTrace{} = payload) do
    secure_broadcast(topic, {:debug_trace, payload})
  end

  @doc "Broadcast a performance analysis"
  def broadcast_performance_analysis(topic, %PerformanceAnalysis{} = payload) do
    secure_broadcast(topic, {:performance_analysis, payload})
  end

  @doc "Broadcast a system state snapshot"
  def broadcast_system_state(topic, %SystemState{} = payload) do
    secure_broadcast(topic, {:system_state, payload})
  end

  @doc "Broadcast an error analysis"
  def broadcast_error_analysis(topic, %ErrorAnalysis{} = payload) do
    secure_broadcast(topic, {:error_analysis, payload})
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

  @doc "Create a DebugTrace payload with current timestamp"
  def debug_trace(component, operation, trace_data, opts \\ []) do
    %DebugTrace{
      trace_id: Keyword.get(opts, :trace_id, generate_trace_id()),
      component: component,
      operation: operation,
      trace_data: trace_data,
      stack_trace: Keyword.get(opts, :stack_trace),
      duration_ms: Keyword.get(opts, :duration_ms),
      node: Keyword.get(opts, :node, Node.self()),
      metadata: Keyword.get(opts, :metadata, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a PerformanceAnalysis payload with current timestamp"
  def performance_analysis(component, analysis_type, findings, opts \\ []) do
    %PerformanceAnalysis{
      analysis_id: Keyword.get(opts, :analysis_id, generate_analysis_id()),
      component: component,
      analysis_type: analysis_type,
      findings: findings,
      recommendations: Keyword.get(opts, :recommendations, []),
      severity: Keyword.get(opts, :severity, :medium),
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a SystemState payload with current timestamp"
  def system_state(snapshot_type, state_data, trigger_reason, opts \\ []) do
    %SystemState{
      snapshot_id: Keyword.get(opts, :snapshot_id, generate_snapshot_id()),
      snapshot_type: snapshot_type,
      state_data: state_data,
      process_count: Keyword.get(opts, :process_count),
      memory_usage: Keyword.get(opts, :memory_usage),
      node: Keyword.get(opts, :node, Node.self()),
      trigger_reason: trigger_reason,
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create an ErrorAnalysis payload with current timestamp"
  def error_analysis(error_type, error_message, opts \\ []) do
    now = DateTime.utc_now()
    
    %ErrorAnalysis{
      error_id: Keyword.get(opts, :error_id, generate_error_id()),
      error_type: error_type,
      error_message: error_message,
      stack_trace: Keyword.get(opts, :stack_trace, []),
      context: Keyword.get(opts, :context, %{}),
      frequency: Keyword.get(opts, :frequency, 1),
      first_seen: Keyword.get(opts, :first_seen, now),
      last_seen: Keyword.get(opts, :last_seen, now),
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: now
    }
  end

  # Private helper functions

  defp generate_trace_id do
    "trace_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_analysis_id do
    "analysis_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_snapshot_id do
    "snapshot_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_error_id do
    "error_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
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
