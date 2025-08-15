defmodule ExESDBGater.Messages.MetricsMessages do
  @moduledoc """
  Message definitions and helpers for the :ex_esdb_metrics PubSub instance.

  Handles performance metrics, measurements, and metric-related events.

  ## Common Topics
  - "performance" - General performance metrics
  - "throughput" - Throughput and rate metrics
  - "latency" - Latency and response time metrics
  - "resource_usage" - CPU, memory, disk usage metrics
  """

  alias Phoenix.PubSub

  @pubsub_instance :ex_esdb_metrics

  # Message payload structs

  @doc "Performance metric payload"
  defmodule PerformanceMetric do
    defstruct [
    :metric_name,    # atom - name of the metric
    :value,          # number - metric value
    :unit,           # string - unit of measurement
    :node,           # atom - node where metric was collected
    :component,      # atom - component that generated the metric
    :tags,           # map - additional metric tags
    :timestamp       # DateTime.t
  ]
  end

  @doc "Throughput metric payload"
  defmodule ThroughputMetric do
    defstruct [
    :operation,      # atom - type of operation
    :count,          # integer - number of operations
    :duration_ms,    # integer - time window in milliseconds
    :rate_per_sec,   # float - operations per second
    :node,           # atom - reporting node
    :timestamp       # DateTime.t
  ]
  end

  @doc "Latency metric payload"
  defmodule LatencyMetric do
    defstruct [
    :operation,      # atom - type of operation
    :latency_ms,     # float - latency in milliseconds
    :percentile,     # atom - :p50 | :p95 | :p99 | :max | :min | :avg
    :sample_count,   # integer - number of samples
    :node,           # atom - reporting node
    :timestamp       # DateTime.t
  ]
  end

  @doc "Resource usage metric payload"
  defmodule ResourceUsage do
    defstruct [
    :resource_type,  # atom - :cpu | :memory | :disk | :network
    :usage_percent,  # float - usage percentage
    :total_available, # integer - total resource available
    :current_used,   # integer - currently used
    :node,           # atom - reporting node
    :timestamp       # DateTime.t
  ]
  end

  @doc "Metric threshold violation payload"
  defmodule MetricAlert do
    defstruct [
    :metric_name,    # atom - name of the metric that violated threshold
    :current_value,  # number - current metric value
    :threshold_value, # number - threshold that was crossed
    :threshold_type, # :min | :max - type of threshold
    :severity,       # :warning | :critical
    :node,           # atom - reporting node
    :timestamp       # DateTime.t
  ]
  end

  # Broadcasting helpers

  @doc "Broadcast a performance metric"
  def broadcast_performance_metric(topic, %PerformanceMetric{} = payload) do
    secure_broadcast(topic, {:performance_metric, payload})
  end

  @doc "Broadcast a throughput metric"
  def broadcast_throughput_metric(topic, %ThroughputMetric{} = payload) do
    secure_broadcast(topic, {:throughput_metric, payload})
  end

  @doc "Broadcast a latency metric"
  def broadcast_latency_metric(topic, %LatencyMetric{} = payload) do
    secure_broadcast(topic, {:latency_metric, payload})
  end

  @doc "Broadcast a resource usage metric"
  def broadcast_resource_usage(topic, %ResourceUsage{} = payload) do
    secure_broadcast(topic, {:resource_usage, payload})
  end

  @doc "Broadcast a metric alert"
  def broadcast_metric_alert(topic, %MetricAlert{} = payload) do
    secure_broadcast(topic, {:metric_alert, payload})
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

  @doc "Create a PerformanceMetric payload with current timestamp"
  def performance_metric(metric_name, value, unit, opts \\ []) do
    %PerformanceMetric{
      metric_name: metric_name,
      value: value,
      unit: unit,
      node: Keyword.get(opts, :node, Node.self()),
      component: Keyword.get(opts, :component),
      tags: Keyword.get(opts, :tags, %{}),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ThroughputMetric payload with current timestamp"
  def throughput_metric(operation, count, duration_ms, opts \\ []) do
    rate_per_sec = count / (duration_ms / 1000.0)
    
    %ThroughputMetric{
      operation: operation,
      count: count,
      duration_ms: duration_ms,
      rate_per_sec: rate_per_sec,
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a LatencyMetric payload with current timestamp"
  def latency_metric(operation, latency_ms, percentile, sample_count, opts \\ []) do
    %LatencyMetric{
      operation: operation,
      latency_ms: latency_ms,
      percentile: percentile,
      sample_count: sample_count,
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a ResourceUsage payload with current timestamp"
  def resource_usage(resource_type, usage_percent, total_available, current_used, opts \\ []) do
    %ResourceUsage{
      resource_type: resource_type,
      usage_percent: usage_percent,
      total_available: total_available,
      current_used: current_used,
      node: Keyword.get(opts, :node, Node.self()),
      timestamp: DateTime.utc_now()
    }
  end

  @doc "Create a MetricAlert payload with current timestamp"
  def metric_alert(metric_name, current_value, threshold_value, threshold_type, severity, opts \\ []) do
    %MetricAlert{
      metric_name: metric_name,
      current_value: current_value,
      threshold_value: threshold_value,
      threshold_type: threshold_type,
      severity: severity,
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
