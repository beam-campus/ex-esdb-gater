import Config

config :ex_unit,
  capture_log: false,
  assert_receive_timeout: 5_000,
  refute_receive_timeout: 1_000,
  exclude: [:skip],
  logger: true

config :ex_esdb_gater, :api,
  pub_sub: :ex_esdb_pub_sub
