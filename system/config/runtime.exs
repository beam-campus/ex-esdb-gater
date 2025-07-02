import Config

alias ExESDBGater.EnVars, as: EnVars
import ExESDBGater.Options

config :ex_esdb_gater, :api,
  connect_to: connect_to(),
  pub_sub: pub_sub()
