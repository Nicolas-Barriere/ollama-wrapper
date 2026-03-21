defmodule OllamaWrapper.RequestStore do
  use GenServer

  @max_entries 1000
  @table :request_store
  @pubsub OllamaWrapper.PubSub
  @topic "request_metrics"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def record(entry) do
    GenServer.cast(__MODULE__, {:record, entry})
  end

  def recent(limit \\ 50) do
    @table
    |> :ets.tab2list()
    |> Enum.sort_by(fn {ts, _} -> ts end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {_ts, entry} -> entry end)
  end

  def summary do
    entries = recent(@max_entries)
    total = length(entries)
    successes = Enum.filter(entries, &(&1.status == :ok))

    avg_latency =
      case successes do
        [] -> 0
        list -> Enum.sum(Enum.map(list, & &1.latency_ms)) / length(list) |> round()
      end

    total_prompt_tokens = Enum.sum(Enum.map(successes, & &1.prompt_tokens))
    total_completion_tokens = Enum.sum(Enum.map(successes, & &1.completion_tokens))

    %{
      total_requests: total,
      successful: length(successes),
      failed: total - length(successes),
      avg_latency_ms: avg_latency,
      total_prompt_tokens: total_prompt_tokens,
      total_completion_tokens: total_completion_tokens
    }
  end

  def topic, do: @topic

  # GenServer callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :ordered_set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:record, entry}, state) do
    ts = System.monotonic_time()
    :ets.insert(@table, {ts, entry})
    prune()
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:new_request, entry})
    {:noreply, state}
  end

  defp prune do
    size = :ets.info(@table, :size)

    if size > @max_entries do
      keys =
        @table
        |> :ets.tab2list()
        |> Enum.sort_by(fn {ts, _} -> ts end)
        |> Enum.take(size - @max_entries)
        |> Enum.each(fn {ts, _} -> :ets.delete(@table, ts) end)

      keys
    end
  end
end
