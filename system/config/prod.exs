import Config

config :logger, :console,
  format: "$time ($metadata) [$level] $message\n",
  metadata: [:mfa],
  level: :debug


config :ex_esdb_gater, :api, pub_sub: :ex_esdb_pubsub

config :swarm, log_level: :error, logger: false
