defmodule ExESDBGater.Themes do
  @moduledoc false
  alias BCUtils.ColorFuncs, as: CF

  def app(pid),
    do: "ExESDB Gater APP [#{CF.blue_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def system(pid),
    do: "ExESDB Gater SYSTEM [#{CF.magenta_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def api(pid),
    do: "ExESDB Gater API [#{CF.green_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def cluster_monitor(pid),
    do: "ExESDB Gater CLUSTER MONITOR [#{CF.cyan_on_black()}#{inspect(pid)}#{CF.reset()}]"

  ################ OBSERVER ################
  def observer(pid),
    do: "OBSERVER [#{CF.bright_yellow_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def observed(msg),
    do: "SEEN [#{CF.bright_green_on_black()}#{inspect(msg)}#{CF.reset()}]"

  ################ SUBSCRIBER ##############
  def subscriber(pid),
    do: "SUBSCRIBER [#{CF.bright_yellow_on_green()}#{inspect(pid)}#{CF.reset()}]"

  def subscription_received(subscription_name, msg),
    do:
      "RECEIVED [#{CF.bright_green_on_black()}#{inspect(subscription_name)} #{inspect(msg)}#{CF.reset()}]"

  ################ PRODUCER ################
  def producer(pid),
    do: "PRODUCER [#{CF.bright_green_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def appended(msg),
    do: "APPENDED [#{CF.bright_yellow_on_black()}#{inspect(msg)}#{CF.reset()}]"
end
