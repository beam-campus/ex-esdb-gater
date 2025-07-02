defmodule ExESDBGater.API do
  @moduledoc """
    The ExESDBGater.API GenServer acts as a simple
    high-availability proxy and load balancer for the 
    GaterWorker processes in the cluster.
  """
  @type store :: atom()
  @type stream :: String.t()
  @type subscription_name :: String.t()
  @type error :: term
  @type subscription_type :: :by_stream | :by_event_type | :by_event_pattern | :by_event_payload
  @type selector_type :: String.t() | map()

  use GenServer
  require Logger
  alias ExESDBGater.Themes, as: Themes

  @doc """
    Gets a list of all gateway worker pids.
  """
  @spec gateway_worker_pids() :: list()
  def gateway_worker_pids,
    do:
      Swarm.registered()
      |> Enum.filter(fn {name, _} -> match?({:gateway_worker, _, _}, name) end)
      |> Enum.map(fn {_, pid} -> pid end)

  @doc """
    Gets a random pid of a gateway worker in the cluster.
  """
  @spec random_gateway_worker() :: pid()
  def random_gateway_worker,
    do:
      gateway_worker_pids()
      |> Enum.random()

  @doc """
    Get the version of a stream.
  """
  @spec get_version(
          store :: atom(),
          stream :: stream
        ) ::
          {:ok, integer} | {:error, term}
  def get_version(store, stream),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:get_version, store, stream}
      )

  @doc """
    Get the subscriptions for a store.
  """
  @spec get_subscriptions(store :: atom()) :: {:ok, list()} | {:error, term}
  def get_subscriptions(store),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:get_subscriptions, store}
      )

  @doc """
    Acknowledge receipt of an event by a subscriber to persistent subscription.
  """
  @spec ack_event(
          store :: atom(),
          subscription_name :: String.t(),
          subscriber_pid :: pid(),
          event :: map()
        ) :: :ok | {:error, term}
  def ack_event(store, subscription_name, subscriber_pid, event),
    do:
      GenServer.cast(
        random_gateway_worker(),
        {:ack_event, store, subscription_name, subscriber_pid, event}
      )

  @doc """
    Append events to a stream.
    ## Parameters
     - store: the id of the store
     - stream_id: the id of the stream
     - events: the events to append
    ## Returns
      {:ok, new_version} where new_version is the new version of the stream
      {:error, reason} if there was an error  
  """
  @spec append_events(
          store :: atom(),
          stream_id :: stream,
          events :: list()
        ) :: {:ok, integer} | {:error, term}
  def append_events(store, stream_id, events),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:append_events, store, stream_id, events}
      )

  @doc """
    Get events from a stream, staring from a given version, in a given direction.
  """
  @spec get_events(
          store :: atom(),
          stream_id :: stream,
          start_version :: integer,
          count :: integer,
          direction :: :forward | :backward
        ) :: {:ok, list()} | {:error, term}
  def get_events(store, stream_id, start_version, count, direction \\ :forward),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:get_events, store, stream_id, start_version, count, direction}
      )

  @doc """
    Get all streams from the store.
    ## Parameters
      - store: the id of the store
    ## Returns
      - a list of all streams in the store
  """
  @spec get_streams(store :: atom()) :: {:ok, list()} | {:error, term()}
  def get_streams(store),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:get_streams, store}
      )

  @doc """
  ## Description
    Add a permanent or transient subscription.
  ## Parameters
  #   - store: the id of the store
  #   - type: the type of subscription (:by_stream, :by_event_type, :by_event_pattern, :by_event_payload)
  #   - selector: the selector for the subscription 
  #   ($all, $<stream-id>, event-type (a string), or event-pattern)
  #   - subscription_name: the name of the subscription, "transient" for a transient subscriptions, except for subscriptions :by_event_pattern or :by_event_payload
  #   - start_from: the version to start from
  #   - subscriber: the pid of the subscriber
  """
  @spec save_subscription(
          store :: atom(),
          type :: atom(),
          selector :: String.t() | map(),
          subscription_name :: String.t(),
          start_from :: non_neg_integer(),
          subscriber :: pid() | nil
        ) :: :ok
  def save_subscription(
        store,
        type,
        selector,
        subscription_name \\ "transient",
        start_from \\ 0,
        subscriber \\ nil
      ) do
    GenServer.cast(
      random_gateway_worker(),
      {:save_subscription, store, type, selector, subscription_name, start_from, subscriber}
    )

    :ok
  end

  @doc """
    Remove a permanent or transient subscription.
  """
  @spec remove_subscription(
          store :: any,
          type :: subscription_type,
          selector :: selector_type,
          subscription_name :: subscription_name
        ) :: :ok | {:error, error}
  def remove_subscription(store, type, selector, subscription_name \\ "transient"),
    do:
      GenServer.cast(
        random_gateway_worker(),
        {:remove_subscription, store, type, selector, subscription_name}
      )

  @spec record_snapshot(
          store :: atom(),
          source_uuid :: binary(),
          stream_uuid :: binary(),
          version :: non_neg_integer(),
          snapshot_record :: map()
        ) :: :ok
  def record_snapshot(store, source_uuid, stream_uuid, version, snapshot_record),
    do:
      GenServer.cast(
        random_gateway_worker(),
        {:record_snapshot, store, source_uuid, stream_uuid, version, snapshot_record}
      )

  @spec delete_snapshot(
          store :: atom(),
          source_uuid :: binary(),
          stream_uuid :: binary(),
          version :: non_neg_integer()
        ) :: :ok
  def delete_snapshot(store, source_uuid, stream_uuid, version),
    do:
      GenServer.cast(
        random_gateway_worker(),
        {:delete_snapshot, store, source_uuid, stream_uuid, version}
      )

  @spec read_snapshot(
          store :: atom(),
          source_uuid :: binary(),
          stream_uuid :: binary(),
          version :: non_neg_integer()
        ) :: {:ok, map()} | {:error, term()}
  def read_snapshot(store, source_uuid, stream_uuid, version),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:read_snapshot, store, source_uuid, stream_uuid, version}
      )

  @spec list_snapshots(
          store :: atom(),
          source_uuid :: binary() | :any,
          stream_uuid :: binary() | :any
        ) :: {:ok, [map()]} | {:error, term()}
  def list_snapshots(store, source_uuid \\ :any, stream_uuid \\ :any),
    do:
      GenServer.call(
        random_gateway_worker(),
        {:list_snapshots, store, source_uuid, stream_uuid}
      )

  ################## PLUMBING ##################
  def init(opts) do
    IO.puts("#{Themes.api(self())} is UP!")
    connect_to = connect_to(opts)
    spawn(fn -> connect_to(connect_to) end)
    {:ok, opts}
  end

  def child_spec(opts),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }

  def start_link(opts),
    do:
      GenServer.start_link(
        __MODULE__,
        opts,
        name: __MODULE__
      )
end
