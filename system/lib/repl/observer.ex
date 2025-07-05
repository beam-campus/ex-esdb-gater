defmodule ExESDBGater.Repl.Observer do
  @moduledoc """
    The Repl.Observer is a GenServer that:
      - adds a transient subscription to the store.
      - subscribes to the events emitted by the store, via Phoenix PubSub.
      - prints the events to the console.
  """

  use GenServer

  require Logger
  alias ExESDB.GatewayAPI, as: API
  alias ExESDB.Options, as: Options
  alias ExESDB.Themes, as: Themes

  @impl true
  def handle_info({:event_emitted, event}, state) do
    %{
      event_stream_id: stream_id,
      event_type: event_type,
      event_number: version,
      data: payload
    } = event

    msg = "#{stream_id}:#{event_type} (v#{version}) => #{inspect(payload, pretty: true)}"

    IO.puts(Themes.observed(msg))

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error("Received unexpected message #{inspect(msg)}")
    {:noreply, state}
  end

  ############## PLUMBING ##############
  @impl true
  def init(args) do
    store = store(args)
    pubsub = pubsub(args)
    selector = selector(args)
    type = type(args)
    name = name(args)

    topic = topic(store, selector, name)

    :ok =
      store
      |> API.save_subscription(type, selector, name)

    :ok =
      pubsub
      |> Phoenix.PubSub.subscribe(topic)

    {:ok, args}
  end

  def start_link(args) do
    store = store(args)
    pubsub = pubsub(args)
    selector = selector(args)
    name = name(args)

    topic = topic(store, selector, name)

    args =
      args
      |> Keyword.put(:store, store)
      |> Keyword.put(:pubsub, pubsub)

    GenServer.start_link(
      __MODULE__,
      args,
      name: Module.concat(__MODULE__, topic)
    )
  end

  @spec start(keyword()) :: pid()
  @doc """
    Starts an observer process for a given topic.
    ## Parameters
    - `store`: The store to consume events from (atom, default: the configured store).
    - `type`: The type of subscription to consume events from (atom, default: `:by_stream`).
    - `selector`: The selector of the subscription to consume events from (string, default: `"$all"`).
    - `topic`: The topic to consume events from (string, default: `reg_gh:$all`).
    - `name`: The name of the observer (string, default: `transient`).
  """
  def start(args) do
    store = store(args)
    selector = selector(args)
    name = name(args)

    topic = topic(store, selector, name)

    case start_link(args) do
      {:ok, pid} ->
        IO.puts("#{Themes.observer(pid)} for [#{inspect(topic)}] is UP!")
        pid

      {:error, {:already_started, pid}} ->
        IO.puts("#{Themes.observer(pid)} for [#{inspect(topic)}] is UP!")
        pid

      {:error, reason} ->
        raise "Failed to start observer for [#{inspect(topic)}]. 
               Reason: #{inspect(reason)}"
    end
  end

  defp store(args), do: Keyword.get(args, :store, Options.store_id())
  defp type(args), do: Keyword.get(args, :type, :by_stream)
  defp selector(args), do: Keyword.get(args, :selector, "$all")
  defp pubsub(args), do: Keyword.get(args, :pubsub, Options.pub_sub())
  defp name(args), do: Keyword.get(args, :name, "transient")

  defp topic(store, selector, "transient"), do: :emitter_group.topic(store, selector)
  defp topic(store, _, name), do: :emitter_group.topic(store, name)
end
