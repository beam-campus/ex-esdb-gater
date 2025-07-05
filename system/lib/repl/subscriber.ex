defmodule ExESDBGater.Repl.Subscriber do
  @moduledoc """
    The Repl.Subscriber is a GenServer that: 
      - creates a permanent subscription to the store.
      - subscribes to the events emitted by the store, by handling events directly.
  """

  use GenServer

  alias ExESDBGater.API, as: API
  alias ExESDBGater.Themes, as: Themes

  require Logger

  @impl true
  def handle_info({:event_emitted, event}, state) do
    %{
      event_stream_id: stream_id,
      event_type: event_type,
      event_number: version,
      data: payload
    } = event

    %{
      store: store,
      subscription_name: subscription_name
    } = state

    msg = "#{stream_id}:#{event_type} v(#{inspect(version)}) => #{inspect(payload, pretty: true)}"
    IO.puts(Themes.subscription_received(subscription_name, msg))

    store
    |> API.ack_event(subscription_name, self(), event)

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @spec start(
          subscription_name :: String.t(),
          stream :: String.t(),
          start_from :: integer()
        ) :: pid()
  def start(subscription_name, stream, start_from \\ 0) do
    args = [
      subscription_name: subscription_name,
      start_from: start_from,
      selector: stream
    ]

    case start_link(args) do
      {:ok, pid} ->
        IO.puts("#{Themes.subscriber(pid)} for [#{inspect(subscription_name)}] is UP!")
        pid

      {:error, {:already_started, pid}} ->
        IO.puts("#{Themes.subscriber(pid)} for [#{inspect(subscription_name)}] is UP!")
        pid

      {:error, reason} ->
        raise "Failed to start subscriber. Reason: #{inspect(reason)}"
    end
  end

  ############## PLUMBING ##############
  @impl true
  def init(args) do
    store = store(args)
    selector = selector(args)
    subscription_name = subscription_name(args)
    start_from = start_from(args)

    store
    |> API.save_subscription(
      :by_stream,
      selector,
      subscription_name,
      start_from,
      self()
    )

    {:ok,
     %{
       store: store,
       subscription_name: subscription_name,
       selector: selector
     }}
  end

  def start_link(args) do
    GenServer.start_link(
      __MODULE__,
      args,
      name: Module.concat(__MODULE__, subscription_name(args))
    )
  end

  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  defp selector(args), do: Keyword.get(args, :selector, "$all")
  defp subscription_name(args), do: Keyword.get(args, :subscription_name, "transient")
  defp start_from(args), do: Keyword.get(args, :start_from, 0)
  defp store(args), do: Keyword.get(args, :store, :reg_gh)
end
