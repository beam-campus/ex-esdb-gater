defmodule ExESDBGater.PubSubManager do
  @moduledoc """
  Local override of BCUtils.PubSubManager that ensures unique child spec IDs.
  Also fixes incorrect pid checking logic.
  """

  @pubsub_config [
    adapter: Phoenix.PubSub.PG2,
    pool_size: 1
  ]

  @doc """
  Returns a child spec for Phoenix.PubSub if not already started, otherwise nil.
  Each child spec has a unique ID based on the pubsub name.
  """
  @spec maybe_child_spec(atom()) :: Supervisor.child_spec() | nil
  def maybe_child_spec(nil), do: nil

  def maybe_child_spec(pubsub_name) when is_atom(pubsub_name) do
    case Process.whereis(pubsub_name) do
      pid when is_pid(pid) ->
        if Process.alive?(pid), do: nil, else: start_pubsub(pubsub_name)

      _ ->
        start_pubsub(pubsub_name)
    end
  end

  defp start_pubsub(pubsub_name) do
    config = Keyword.merge(@pubsub_config, name: pubsub_name)
    Supervisor.child_spec({Phoenix.PubSub, config}, id: :"#{pubsub_name}_pubsub")
  end
end
