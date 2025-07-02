import Config

config :partisan,
  peer_service_manager: Partisan.PeerServiceManager.Ets,
  

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:mfa]

import_config "#{Mix.env()}.exs"
