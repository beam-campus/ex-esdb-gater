defmodule ExESDBGater.Repl.Producer do
  @moduledoc false
  use GenServer

  require Logger

  alias ExESDBGater.API, as: API
  alias ExESDBGater.Repl.EventGenerator, as: ESGen
  alias ExESDBGater.Repl.Themes, as: Themes

  @impl true
  def handle_info(:produce, state) do
    stream_id = stream_id(state)
    store = store(state)
    batch_size = batch_size(state)
    period = period(state)

    store
    |> append(stream_id, batch_size)

    produce(period)
    {:noreply, state}
  end

  ############## PLUMBING ##############
  @impl true
  def init(args) do
    period = period(args)
    produce(period)
    {:ok, args}
  end

  def start_link(args) do
    stream_id = stream_id(args)

    GenServer.start_link(
      __MODULE__,
      args,
      name: Module.concat(__MODULE__, stream_id)
    )
  end

  @doc """
    Starts a producer process for testing purposes.
    ## Parameters
      * `stream_id`: The id of the stream to append events to (string, default: `greenhouse0`).
      * `batch_size`: The number of events to append in a single batch (integer, default: `1`).
      * `period`: The time in milliseconds between appending events (integer, default: `2000`).
  """
  @spec start(
          stream_id :: String.t(),
          batch_size :: integer(),
          period :: integer()
        ) :: pid()
  def start(stream_id \\ "greenhouse0", batch_size \\ 1, period \\ 2_000) do
    store = :reg_gh
    args = [store: store, stream_id: stream_id, batch_size: batch_size, period: period]

    case start_link(args) do
      {:ok, pid} ->
        IO.puts("#{Themes.producer(pid)} for [#{inspect(store)}:#{stream_id}] is UP!")
        pid

      {:error, {:already_started, pid}} ->
        IO.puts("#{Themes.producer(pid)} for [#{inspect(store)}:#{stream_id}] is already UP!")

        pid

      {:error, reason} ->
        raise "Failed to start producer. Reason: #{inspect(reason)}"
    end
  end

  @spec stop(stream_id :: String.t()) :: :ok
  def stop(stream_id),
    do:
      GenServer.stop(
        Module.concat(__MODULE__, stream_id),
        :normal
      )

  defp store(args), do: Keyword.get(args, :store, :reg_gh)
  defp stream_id(args), do: Keyword.get(args, :stream_id, "greenhouse0")
  defp batch_size(args), do: Keyword.get(args, :batch_size, 1)
  defp period(args), do: Keyword.get(args, :period, 2_000)
  defp produce(period), do: Process.send_after(self(), :produce, :rand.uniform(period * 5))

  defp append(store, stream_id, nbr_of_events) do
    version =
      store
      |> API.get_version(stream_id)

    events = ESGen.generate_events(version, nbr_of_events)

    {:ok, new_version} =
      store
      |> API.append_events(stream_id, events)

    msg = "#{nbr_of_events} event(s) to #{inspect(store)}:#{stream_id}.v(#{new_version})"

    IO.puts(Themes.appended(msg))
  end
end
