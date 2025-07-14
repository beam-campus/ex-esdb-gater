defmodule ExESDBGater.LibClusterHelper do
  @moduledoc false
  require Logger
  alias ExESDBGater.SharedClusterConfig, as: Config
  alias ExESDBGater.Themes, as: Themes

  @startup_delay_ms 100
  @startup_check_timeout_ms 5_000

  # Helper function to conditionally add LibCluster supervisor
  # Uses a shared name to prevent conflicts between ExESDB and ExESDBGater
  def maybe_add_libcluster(_topologies) do
    # Add startup delay to prevent race conditions
    Process.sleep(@startup_delay_ms)

    # Use unified configuration instead of passed topologies
    unified_topologies = Config.topology()

    # Validate configuration
    case Config.validate_config() do
      :ok ->
        :ok

      {:warning, issues} ->
        Enum.each(issues, &Logger.warning/1)
    end

    case check_libcluster_status() do
      :not_running ->
        Logger.info("#{Themes.system(self(), "Starting SharedLibCluster with unified config")}")
        {Cluster.Supervisor, [unified_topologies, [name: SharedLibCluster]]}

      :running ->
        Logger.info("#{Themes.system(self(), "SharedLibCluster already running, skipping")}")
        nil

      :failed ->
        Logger.warning(
          "#{Themes.system(self(), "Failed to determine LibCluster status, proceeding with caution")}"
        )

        nil
    end
  end

  # Check LibCluster status with timeout protection
  defp check_libcluster_status do
    task =
      Task.async(fn ->
        case Process.whereis(SharedLibCluster) do
          nil -> :not_running
          _pid -> :running
        end
      end)

    case Task.yield(task, @startup_check_timeout_ms) do
      {:ok, result} ->
        result

      nil ->
        Task.shutdown(task, :brutal_kill)
        :failed
    end
  end
end
