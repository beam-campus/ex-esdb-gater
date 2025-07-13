defmodule ExESDBGater.LibClusterHelper do
  require Logger
  alias ExESDBGater.Themes, as: Themes

  # Helper function to conditionally add LibCluster supervisor
  # Uses a shared name to prevent conflicts between ExESDB and ExESDBGater
  def maybe_add_libcluster(topologies) do
    case Process.whereis(SharedLibCluster) do
      nil ->
        Logger.info("#{Themes.system(self(), "Starting SharedLibCluster")}")
        {Cluster.Supervisor, [topologies, [name: SharedLibCluster]]}

      _pid ->
        Logger.info("#{Themes.system(self(), "SharedLibCluster already running, skipping")}")
        nil
    end
  end
end

