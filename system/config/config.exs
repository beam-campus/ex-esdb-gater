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

import_config "#{Mix.env()}.exs"
