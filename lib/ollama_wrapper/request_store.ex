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
            completion_tokens: e.completion_tokens
          }
      )

    successful = length(ok_events)

    avg_latency =
      case ok_events do
        [] -> 0
        list -> (Enum.sum(Enum.map(list, & &1.latency_ms)) / successful) |> round()
      end

    %{
      total_requests: total,
      successful: successful,
      failed: total - successful,
      avg_latency_ms: avg_latency,
      total_prompt_tokens: Enum.sum(Enum.map(ok_events, & &1.prompt_tokens)),
      total_completion_tokens: Enum.sum(Enum.map(ok_events, & &1.completion_tokens))
    }
  end

  def topic, do: @topic
end
