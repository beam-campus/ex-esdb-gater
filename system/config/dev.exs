import Config

alias ExESDBGater.EnVars, as: EnVars

config :swarm,
  log_level: :error,
  logger: true

# Additional logger configuration for cleaner output
config :logger,
  backends: [:console],
  handle_otp_reports: true,
  handle_sasl_reports: false

config :logger, :console,
  format: "$time ($metadata) [$level] $message\n",
  metadata: [:mfa],
  level: :info,
  # Filter out Swarm noise using BCUtils filter
  filters: [swarm_noise: {BCUtils.LoggerFilters, :filter_swarm}]

config :ex_esdb_gater, :logger, level: :debug

