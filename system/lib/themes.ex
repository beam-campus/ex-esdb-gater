defmodule ExESDBGater.Themes do
  @moduledoc false
  alias BCUtils.ColorFuncs, as: CF

  def app(pid),
    do: "[#{CF.blue_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def system(pid),
    do: "[#{CF.magenta_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def api(pid),
    do: "[#{CF.green_on_black()}#{inspect(pid)}#{CF.reset()}]"

  def cluster_monitor(pid),
    do: "[#{CF.cyan_on_black()}#{inspect(pid)}#{CF.reset()}]"
end
