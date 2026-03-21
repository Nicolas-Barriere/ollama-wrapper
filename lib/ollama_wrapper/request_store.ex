defmodule OllamaWrapper.RequestStore do
  import Ecto.Query

  alias OllamaWrapper.{Repo, RequestEvent}

  @pubsub OllamaWrapper.PubSub
  @topic "request_metrics"

  def record(attrs) do
    %RequestEvent{}
    |> RequestEvent.changeset(attrs)
    |> Repo.insert!()

    Phoenix.PubSub.broadcast(@pubsub, @topic, {:new_request, attrs})
  end

  def recent(limit \\ 50) do
    Repo.all(
      from e in RequestEvent,
        order_by: [desc: e.timestamp],
        limit: ^limit
    )
  end

  def summary do
    total = Repo.aggregate(RequestEvent, :count, :id)

    ok_events =
      Repo.all(
        from e in RequestEvent,
          where: e.status == :ok,
          select: %{
            latency_ms: e.latency_ms,
            prompt_tokens: e.prompt_tokens,
            completion_tokens: e.completion_tokens,
            thinking_duration_ms: e.thinking_duration_ms,
            output_duration_ms: e.output_duration_ms
          }
      )

    successful = length(ok_events)

    avg_latency =
      case ok_events do
        [] -> 0
        list -> (Enum.sum(Enum.map(list, & &1.latency_ms)) / successful) |> round()
      end

    avg_tokens_per_sec =
      case ok_events do
        [] ->
          0.0

        list ->
          speeds = Enum.flat_map(list, fn e ->
            gen_ms = (e.thinking_duration_ms || 0) + (e.output_duration_ms || 0)
            if gen_ms > 0, do: [e.completion_tokens / (gen_ms / 1000)], else: []
          end)

          case speeds do
            [] -> 0.0
            _ -> Float.round(Enum.sum(speeds) / length(speeds), 1)
          end
      end

    %{
      total_requests: total,
      successful: successful,
      failed: total - successful,
      avg_latency_ms: avg_latency,
      avg_tokens_per_sec: avg_tokens_per_sec,
      total_prompt_tokens: Enum.sum(Enum.map(ok_events, & &1.prompt_tokens)),
      total_completion_tokens: Enum.sum(Enum.map(ok_events, & &1.completion_tokens))
    }
  end

  def topic, do: @topic
end
