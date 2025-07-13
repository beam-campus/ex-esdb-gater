defmodule ExESDBGater.System do
  @moduledoc """
    The APISystem is responsible for starting and supervising the
    APIWorkers.
  """
  use Supervisor
  require Logger

  alias ExESDBGater.Themes, as: Themes
  alias ExESDBGater.LibClusterHelper, as: LibClusterHelper

  alias BCUtils.PubSubManager

  @impl Supervisor
  def init(opts) do
    pub_sub = Keyword.get(opts, :pub_sub)
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      [
        LibClusterHelper.maybe_add_libcluster(topologies),
        {ExESDBGater.ClusterMonitor, opts},
        maybe_add_pubsub(pub_sub),
        {ExESDBGater.API, opts}
      ]
      # Remove nil entries
      |> Enum.filter(& &1)

    IO.puts(Themes.system(self(), "is UP!"))
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

  # Helper function to conditionally add Phoenix.PubSub using PubSubManager
  defp maybe_add_pubsub(pub_sub_name) do
    PubSubManager.maybe_child_spec(pub_sub_name)
  end
end
