import Config

alias ExESDBGater.EnVars, as: EnVars
import ExESDBGater.Options

config :ex_esdb_gater, :api,
  connect_to: connect_to(),
  pub_sub: pub_sub()

config :swarm,
  logger: false

# LibCluster configuration now uses SharedClusterConfig for consistency
# This prevents conflicts between ExESDB and ExESDBGater
config :libcluster,
  topologies: ExESDBGater.SharedClusterConfig.topology()
