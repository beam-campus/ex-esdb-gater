defmodule ExESDBGater.App do
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
      {ExESDBGater.System, config}
    ]

    opts = [strategy: :one_for_one, name: ExESDBGater.Supervisor]
    res = Supervisor.start_link(children, opts)
    IO.puts("#{Themes.app(self())} is UP!")

    res
  end
end
