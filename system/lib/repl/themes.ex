defmodule ExESDBGater.Repl.Themes do
  @moduledoc false
  alias BCUtils.ColorFuncs, as: CF

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
