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
end
