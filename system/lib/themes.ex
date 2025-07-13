defmodule ExESDBGater.Themes do
  @moduledoc false
  alias BCUtils.ColorFuncs, as: CF

  def app(pid, msg),
    do: "[#{CF.blue_on_black()}#{inspect(pid)}#{CF.reset()}] [GaterApp] #{msg}"

  def system(pid, msg),
    do: "[#{CF.magenta_on_black()}#{inspect(pid)}#{CF.reset()}] [GaterSystem] #{msg}"

  def api(pid, msg),
    do: "[#{CF.green_on_black()}#{inspect(pid)}#{CF.reset()}] [GaterAPI] #{msg}"

  def cluster_monitor(pid, msg),
    do: "[#{CF.cyan_on_black()}#{inspect(pid)}#{CF.reset()}] [ClusterMonitor] #{msg}"
end
