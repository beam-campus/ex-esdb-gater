defmodule ExESDBGater.PubSubSystem do
  @moduledoc """
  Supervisor for all PubSub instances used by ExESDBGater.
  """
  use Supervisor

  alias ExESDBGater.PubSubManager

  @pubsub_instances [:ex_esdb_events, :ex_esdb_system, :ex_esdb_logging]

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    children =
      for name <- @pubsub_instances do
        PubSubManager.maybe_child_spec(name)
      end
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
