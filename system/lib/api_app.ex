defmodule ExESDBGater.APIApp do
  @moduledoc false

  use Application,
    otp_app: :ex_esdb_gater

  alias ExESDBGater.Options, as: Options
  alias ExESDBGater.Themes, as: Themes

  require Logger
  @impl Application
  def start(_type, _args) do
    config = Options.api_env()

    children = [
      {ExESDBGater.APISystem, [config]}
    ]

    opts = [strategy: :one_for_one, name: ExESDBGater.APISupervisor]
    res = Supervisor.start_link(children, opts)
    IO.puts("#{Themes.app(self())} is UP!")

    service_name = "ExESDB Gater"
    service_description = "Gateway Service for ExESDB"
    shoutout = "🌐 Ready for routing!"

    BCUtils.Banner.display_banner(service_name, service_description, shoutout)
    res
  end
end
