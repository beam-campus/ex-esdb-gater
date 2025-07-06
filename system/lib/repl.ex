defmodule ExESDBGater.Repl do
  @moduledoc """
    This module is to interact with the ExESDB.system, 
    running a store called "reg_gh" (Regulate Greenhouse)
    
  """
  alias ExESDBGater.Repl.EventGenerator, as: ESGen
  alias ExESDBGater.Repl.Observer, as: Observer
  alias ExESDBGater.Repl.Producer, as: Producer
  alias ExESDBGater.Repl.Subscriber, as: Subscriber

  alias ExESDBGater.API, as: API

  require Logger

  @store :reg_gh
  @greenhouse1 "greenhouse1"
  @greenhouse2 "greenhouse2"
  @greenhouse3 "greenhouse3"
  @greenhouse4 "greenhouse4"
  @greenhouse5 "greenhouse5"

  @greenhouses [
    @greenhouse1,
    @greenhouse2,
    @greenhouse3,
    @greenhouse4,
    @greenhouse5
  ]

  def store, do: @store
  def stream1, do: @greenhouse1
  def stream2, do: @greenhouse2
  def stream3, do: @greenhouse3
  def stream4, do: @greenhouse4
  def stream5, do: @greenhouse5

  def get_streams, do: API.get_streams(@store)

  def get_subscriptions, do: API.get_subscriptions(@store)

  @doc """
    Append events to a stream.
  """
  @spec append(
          stream :: atom(),
          nbr_of_events :: integer()
        ) :: {:ok, list(), integer()} | {:error, term()}
  def append(stream, nbr_of_events) do
    {:ok, version} = API.get_version(@store, stream)

    events = ESGen.generate_events(version, nbr_of_events)

    case @store
         |> API.append_events(stream, events) do
      {:ok, new_version} ->
        {:ok, result} =
          @store
          |> API.get_events(stream, 1, new_version, :forward)

        {:ok, result,
         result
         |> Enum.count()}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Starts an observer (a transient subscription) for all streams.
  """
  @spec start_observer_for_all_streams() :: :ok
  def start_observer_for_all_streams do
    Observer.start(
      store: @store,
      type: :by_stream,
      selector: "$all"
    )

    :ok
  end

  @doc """
    Starts an observer (a transient subscription) for a specific stream.
    ## Parameters
     - stream: the stream to subscribe to (default: "$greenhouse-1")
  """
  @spec start_observer_for_stream(stream :: String.t()) :: :ok
  def start_observer_for_stream(stream \\ "$greenhouse-1") do
    Observer.start(
      store: @store,
      type: :by_stream,
      selector: stream
    )

    :ok
  end

  @doc """
    Starts an observer for a specific event type.
    ## Possible event types:
    - "initialized:v1" (default)
    - "temperature_measured:v1"
    - "humidity_measured:v1"
    - "light_measured:v1"
    - "fan_activated:v1"
    - "fan_deactivated:v1"
    - "light_activated:v1"
    - "light_deactivated:v1"
    - "heater_activated:v1"
    - "heater_deactivated:v1"
    - "sprinkler_activated:v1"
    - "sprinkler_deactivated:v1"
    - "desired_temperature_set:v1"
    - "desired_humidity_set:v1"
    - "desired_light_set:v1"
  """
  @spec start_observer_for_event_type(event_type :: String.t()) :: :ok
  def start_observer_for_event_type(event_type \\ "initialized:v1") do
    Observer.start(
      store: @store,
      type: :by_event_type,
      selector: event_type
    )

    :ok
  end

  @doc """
    Starts an observer (a transient subscription) for a specific event payload pattern.
    ## Parameters
     - observer_name: the name of the observer
     - event_payload_pattern: the event payload pattern as a map (e.g.: %{operator: "John"})
  """
  def start_observer_for_event_payload(
        observer_name,
        event_payload_pattern
      ) do
    Observer.start(
      store: @store,
      type: :by_event_payload,
      selector: event_payload_pattern,
      name: observer_name
    )

    :ok
  end

  @doc """
    Starts a subscriber for a specific stream.
    ## Parameters
      - subscription_name: the name of the subscription
      - stream: the stream to subscribe to (default: "$greenhouse-1")
      - start_from: the version to start from (default: 0)
  """
  @spec start_subscriber_for_stream(
          subscription_name :: String.t(),
          stream :: String.t(),
          start_from :: integer()
        ) :: :ok
  def start_subscriber_for_stream(subscription_name, stream \\ "$greenhouse-1", start_from \\ 0) do
    Subscriber.start(
      subscription_name,
      stream,
      start_from
    )

    :ok
  end

  @doc """
    Starts a number of producers. 
    Each producer will append events to a stream with stream id `greenhouse-n`.
    Where n is the number of the producer.
  """
  def start_producers(nbr_of_producers \\ 10) do
    1..nbr_of_producers
    |> Enum.each(fn n -> Producer.start("greenhouse-#{n}") end)

    :ok
  end

  @doc """
    Stops a producer for a specific stream_id.
  """
  @spec stop_producer_for_stream(stream_id :: String.t()) :: :ok
  def stop_producer_for_stream(stream_id \\ "greenhouse-1") do
    Producer.stop(stream_id)
  end
end
