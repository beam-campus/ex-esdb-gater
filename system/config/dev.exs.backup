import Config

alias ExESDBGater.EnVars, as: EnVars

config :swarm,
  log_level: :info,
  logger: true

config :logger, :console,
  format: "$time ($metadata) [$level] $message\n",
  metadata: [:mfa],
  level: :info

config :ex_esdb_gater, :logger, level: :debug

config :ex_esdb_gater, :api,
  connect_to: "ex_esdb@arch00",
  pub_sub: :ex_esdb_pubsub
