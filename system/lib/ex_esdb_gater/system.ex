defmodule ExESDBGater.System do
  @moduledoc """
    The APISystem is responsible for starting and supervising the
    APIWorkers.
  """
  use Supervisor
  require Logger
  alias ExESDBGater.Themes, as: Themes

  @impl Supervisor
  def init(opts) do
    pub_sub = Keyword.get(opts, :pub_sub)
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      [
        {Cluster.Supervisor, [topologies, [name: ExESDBGater.LibCluster]]},
        {ExESDBGater.ClusterMonitor, opts},
        {Phoenix.PubSub, name: pub_sub},
        {ExESDBGater.API, opts}
      ]

    IO.puts("#{Themes.system(self())} is UP!")
    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts),
    do:
      Supervisor.start_link(
        __MODULE__,
        opts,
        name: __MODULE__
      )

  def child_spec(opts),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 5000
    }
end
