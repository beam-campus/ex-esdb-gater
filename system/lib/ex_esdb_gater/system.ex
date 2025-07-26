defmodule ExESDBGater.System do
  @moduledoc """
    The APISystem is responsible for starting and supervising the
    APIWorkers.
  """
  use Supervisor
  require Logger

  alias ExESDBGater.LibClusterHelper, as: LibClusterHelper
  alias ExESDBGater.Themes, as: Themes

  @impl Supervisor
  def init(opts) do
    # Handle the case where opts might be nil (no configuration provided)
    opts = opts || []
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      [
        LibClusterHelper.maybe_add_libcluster(topologies),
        {ExESDBGater.ClusterMonitor, opts},
        # Start PubSub system
        {ExESDBGater.PubSubSystem, opts},
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

end
