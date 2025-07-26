import Config

config :swarm,
  logger: false

# LibCluster configuration now uses SharedClusterConfig for consistency
# This prevents conflicts between ExESDB and ExESDBGater
config :libcluster,
  topologies: ExESDBGater.SharedClusterConfig.topology()
