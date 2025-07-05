import Config

# Partisan configuration for server discovery
config :partisan,
  peer_service_manager: Partisan.PeerServiceManager.HyParView,
  partisan_peer_service_manager: Partisan.PeerServiceManager.HyParView,
  connect_disterl: false,
  parallelism: 1,
  channels: [:data, :control],
  disable_fast_receive: false,
  membership_strategy: Partisan.MembershipStrategy.FullMembership,
  broadcast_mods: [],
  disterl: false,
  # Gateway tag for discovery
  tag: :gateway,
  # Enable peer discovery to find ExESDB servers
  peer_discovery: %{
    enabled: true,
    type: :partisan_peer_discovery_list,
    config: %{
      # Will discover ExESDB servers in the network
      peers: [],  # Will be populated from EXESDB_SERVERS env var
      poll_interval: 10_000
    },
    initial_delay: 2_000,
    polling_interval: 15_000,
    timeout: 5_000
  }

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:mfa]

# Reduce Swarm logging noise - only show true errors
config :swarm,
  log_level: :error

# Configure specific modules' log levels - only show errors
config :logger,
  compile_time_purge_matching: [
    # Swarm modules - only show errors
    [module: Swarm.Distribution.Ring, level_lower_than: :error],
    [module: Swarm.Distribution.Strategy, level_lower_than: :error],
    [module: Swarm.Registry, level_lower_than: :error],
    [module: Swarm.Tracker, level_lower_than: :error],
    [module: Swarm.Distribution.StaticQuorumRing, level_lower_than: :error],
    [module: Swarm.Distribution.Handler, level_lower_than: :error],
    [module: Swarm.IntervalTreeClock, level_lower_than: :error],
    [module: Swarm.Logger, level_lower_than: :error],
    [module: Swarm, level_lower_than: :error]
  ]

import_config "#{Mix.env()}.exs"
