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

  def recent(limit \\ 50, filters \\ %{}) do
    from(e in RequestEvent, order_by: [desc: e.timestamp], limit: ^limit)
    |> apply_filter(:search, Map.get(filters, :search))
    |> apply_filter(:status, Map.get(filters, :status))
    |> apply_filter(:model, Map.get(filters, :model))
    |> Repo.all()
  end

  def models do
    Repo.all(from e in RequestEvent, select: e.model, distinct: true, order_by: e.model)
  end

  defp apply_filter(query, :search, term) when is_binary(term) and term != "" do
    pattern = "%#{term}%"
    where(query, [e], ilike(e.message, ^pattern) or ilike(e.response, ^pattern))
  end

  defp apply_filter(query, :status, "ok"), do: where(query, [e], e.status == :ok)
  defp apply_filter(query, :status, "error"), do: where(query, [e], e.status == :error)
  defp apply_filter(query, :model, model) when is_binary(model) and model != "",
    do: where(query, [e], e.model == ^model)

  defp apply_filter(query, _key, _val), do: query

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

  def time_series(range \\ "1d", granularity \\ "hour") do
    since = range_to_since(range)
    trunc = granularity_to_trunc(granularity)

    # Use raw SQL with GROUP BY 1 positional reference to avoid Ecto's restriction
    # on runtime fragment interpolation and PostgreSQL's duplicate-parameter issue.
    # `trunc` is validated to a fixed safe set so interpolation is safe here.
    {where_sql, params} =
      if since do
        {"WHERE timestamp >= $2", [trunc, since]}
      else
        {"", [trunc]}
      end

    sql = """
    SELECT
      date_trunc($1, timestamp) AS bucket,
      count(*) AS total,
      count(*) FILTER (WHERE status = 'ok') AS successful,
      count(*) FILTER (WHERE status = 'error') AS failed,
      avg(
        CASE WHEN coalesce(thinking_duration_ms,0) + coalesce(output_duration_ms,0) > 0
          THEN cast(completion_tokens AS float) / ((coalesce(thinking_duration_ms,0) + coalesce(output_duration_ms,0)) / 1000.0)
        END
      ) AS avg_tok_sec
    FROM request_events
    #{where_sql}
    GROUP BY 1
    ORDER BY 1
    """

    {:ok, %{rows: rows}} = Repo.query(sql, params)

    Enum.map(rows, fn [bucket, total, successful, failed, avg_tok_sec] ->
      %{bucket: bucket, total: total, successful: successful, failed: failed, avg_tok_sec: avg_tok_sec}
    end)
  end

  defp range_to_since("all"), do: nil
  defp range_to_since("1h"), do: DateTime.add(DateTime.utc_now(), -3600, :second)
  defp range_to_since("1d"), do: DateTime.add(DateTime.utc_now(), -86400, :second)
  defp range_to_since("1w"), do: DateTime.add(DateTime.utc_now(), -7 * 86400, :second)
  defp range_to_since("1m"), do: DateTime.add(DateTime.utc_now(), -30 * 86400, :second)
  defp range_to_since("1y"), do: DateTime.add(DateTime.utc_now(), -365 * 86400, :second)

  defp granularity_to_trunc(g) when g in ["minute", "hour", "day", "week", "month"], do: g

  def topic, do: @topic
end
