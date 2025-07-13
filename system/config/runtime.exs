import Config

alias ExESDBGater.EnVars, as: EnVars
import ExESDBGater.Options

config :ex_esdb_gater, :api,
  connect_to: connect_to(),
  pub_sub: pub_sub()

config :swarm,
  logger: false

config :libcluster,
  topologies: [
    ex_esdb_gater: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Gossip,
      # Configuration for the selected strategy. Optional.
      config: [
        port: 45_892,
        # The IP address or hostname on which to listen for cluster connections.
        if_addr: "0.0.0.0",
        # Use broadcast for cluster discovery
        multicast_addr: System.get_env("EX_ESDB_GOSSIP_MULTICAST_ADDR") || "255.255.255.255",
        broadcast_only: true,
        # Shared secret for cluster security - read from environment at runtime
        secret: System.get_env("EX_ESDB_CLUSTER_SECRET") || "dev_cluster_secret"
      ]
    ]
  ]
