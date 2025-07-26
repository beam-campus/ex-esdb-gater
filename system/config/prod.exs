import Config

config :logger, :console,
  format: "$time ($metadata) [$level] $message\n",
  metadata: [:mfa],
  level: :debug



config :swarm, log_level: :error, logger: false
