defmodule ExESDBGater.Config do
  @moduledoc """
  Configuration validation and normalization for ExESDBGater.

  This module provides standardized configuration handling with proper validation,
  error handling, and normalization to ensure consistent behavior across the system.
  """

  require Logger

  @type config :: Keyword.t()
  @type gater_config :: map()

  @doc """
  Validates and normalizes configuration for ExESDBGater.

  ## Options

  * `:cluster_mode` - Whether to run in cluster mode (default: `false`)
  * `:port` - Port to listen on for HTTP API (default: `4001`)
  * `:max_connections` - Maximum number of concurrent connections (default: `1000`)
  * `:pool_size` - Size of worker pools (default: `10`)
  * `:use_libcluster` - Whether to use libcluster for node discovery (default: `true`)
  * `:connection_retry_interval` - Interval between connection retries in ms (default: `5000`)
  * `:health_check_interval` - Interval for health checks in ms (default: `30000`)

  ## Examples

      iex> ExESDBGater.Config.validate([port: 4001])
      {:ok, %{port: 4001, cluster_mode: false, ...}}
  """
  @spec validate(config()) :: {:ok, gater_config()} | {:error, {atom(), term()}}
  def validate(config) when is_list(config) do
    try do
      normalize_config(config)
    rescue
      error -> {:error, {:validation_error, error}}
    end
  end

  @doc """
  Gets the cluster mode configuration.
  """
  @spec cluster_mode?(config()) :: boolean()
  def cluster_mode?(config) do
    case get_config_value(config, :cluster_mode, "EXESDB_GATER_CLUSTER_MODE") do
      nil -> false
      value when is_boolean(value) -> value
      "true" -> true
      "false" -> false
      other -> raise ArgumentError, "cluster_mode must be a boolean, got: #{inspect(other)}"
    end
  end

  @doc """
  Gets the port configuration.
  """
  @spec port(config()) :: non_neg_integer()
  def port(config) do
    case get_config_value(config, :port, "EXESDB_GATER_PORT") do
      nil ->
        4001

      value when is_integer(value) and value > 0 and value <= 65_535 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_val, ""} when int_val > 0 and int_val <= 65_535 -> int_val
          _ -> raise ArgumentError, "port must be a valid port number (1-65535)"
        end
    end
  end

  @doc """
  Gets the maximum connections configuration.
  """
  @spec max_connections(config()) :: pos_integer()
  def max_connections(config) do
    case get_config_value(config, :max_connections, "EXESDB_GATER_MAX_CONNECTIONS") do
      nil ->
        1000

      value when is_integer(value) and value > 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_val, ""} when int_val > 0 -> int_val
          _ -> raise ArgumentError, "max_connections must be a positive integer"
        end
    end
  end

  @doc """
  Gets the pool size configuration.
  """
  @spec pool_size(config()) :: pos_integer()
  def pool_size(config) do
    case get_config_value(config, :pool_size, "EXESDB_GATER_POOL_SIZE") do
      nil ->
        10

      value when is_integer(value) and value > 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_val, ""} when int_val > 0 -> int_val
          _ -> raise ArgumentError, "pool_size must be a positive integer"
        end
    end
  end

  @doc """
  Checks if libcluster should be used for node discovery.
  """
  @spec use_libcluster?(config()) :: boolean()
  def use_libcluster?(config) do
    case get_config_value(config, :use_libcluster, "EXESDB_GATER_USE_LIBCLUSTER") do
      nil -> true
      value when is_boolean(value) -> value
      "true" -> true
      "false" -> false
      other -> raise ArgumentError, "use_libcluster must be a boolean, got: #{inspect(other)}"
    end
  end

  @doc """
  Gets the connection retry interval configuration.
  """
  @spec connection_retry_interval(config()) :: pos_integer()
  def connection_retry_interval(config) do
    case get_config_value(
           config,
           :connection_retry_interval,
           "EXESDB_GATER_CONNECTION_RETRY_INTERVAL"
         ) do
      nil ->
        5000

      value when is_integer(value) and value > 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_val, ""} when int_val > 0 -> int_val
          _ -> raise ArgumentError, "connection_retry_interval must be a positive integer"
        end
    end
  end

  @doc """
  Gets the health check interval configuration.
  """
  @spec health_check_interval(config()) :: pos_integer()
  def health_check_interval(config) do
    case get_config_value(config, :health_check_interval, "EXESDB_GATER_HEALTH_CHECK_INTERVAL") do
      nil ->
        30_000

      value when is_integer(value) and value > 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_val, ""} when int_val > 0 -> int_val
          _ -> raise ArgumentError, "health_check_interval must be a positive integer"
        end
    end
  end

  @doc """
  Validates libcluster topology configuration.
  """
  @spec validate_libcluster_config(config()) :: {:ok, config()} | {:error, term()}
  def validate_libcluster_config(config) do
    if use_libcluster?(config) do
      case Application.get_env(:libcluster, :topologies) do
        nil ->
          Logger.warning("libcluster is enabled but no topologies configured")
          {:ok, config}

        topologies when is_list(topologies) ->
          Logger.info("libcluster enabled with #{length(topologies)} topologies")
          {:ok, config}

        invalid ->
          {:error, {:invalid_libcluster_config, invalid}}
      end
    else
      {:ok, config}
    end
  end

  # Private functions

  defp normalize_config(config) do
    normalized = %{
      cluster_mode: cluster_mode?(config),
      port: port(config),
      max_connections: max_connections(config),
      pool_size: pool_size(config),
      use_libcluster: use_libcluster?(config),
      connection_retry_interval: connection_retry_interval(config),
      health_check_interval: health_check_interval(config)
    }

    with {:ok, _} <- validate_libcluster_config(config) do
      {:ok, normalized}
    end
  end

  defp get_config_value(config, key, env_var) do
    case Keyword.get(config, key) do
      nil when is_binary(env_var) -> System.get_env(env_var)
      nil -> nil
      value -> value
    end
  end
end
