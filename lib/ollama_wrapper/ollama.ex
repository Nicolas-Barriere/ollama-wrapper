defmodule OllamaWrapper.Ollama do
  require Logger

  @base_url "http://localhost:11434"
  @model "qwen3:8b"

  def chat(message, system \\ nil) do
    messages =
      if system do
        [%{role: "system", content: system}, %{role: "user", content: message}]
      else
        [%{role: "user", content: message}]
      end

    payload = %{model: @model, messages: messages, stream: false}
    start_time = System.monotonic_time()

    case Req.post("#{@base_url}/v1/chat/completions", json: payload, receive_timeout: 120_000) do
      {:ok, %{status: 200, body: body}} ->
        latency_ms = native_to_ms(System.monotonic_time() - start_time)
        usage = Map.get(body, "usage", %{})
        prompt_tokens = Map.get(usage, "prompt_tokens", 0)
        completion_tokens = Map.get(usage, "completion_tokens", 0)
        content = get_in(body, ["choices", Access.at(0), "message", "content"])

        measurements = %{
          latency_ms: latency_ms,
          prompt_tokens: prompt_tokens,
          completion_tokens: completion_tokens
        }

        :telemetry.execute(
          [:ollama_wrapper, :request, :success],
          measurements,
          %{model: @model}
        )

        Logger.info(
          "[Ollama] #{latency_ms}ms | in:#{prompt_tokens} out:#{completion_tokens} tokens | model:#{@model} | response: #{String.slice(content, 0, 200)}"
        )

        OllamaWrapper.RequestStore.record(%{
          status: :ok,
          model: @model,
          latency_ms: latency_ms,
          prompt_tokens: prompt_tokens,
          completion_tokens: completion_tokens,
          timestamp: DateTime.utc_now(),
          message_preview: String.slice(message, 0, 100)
        })

        {:ok, %{response: content, model: @model, prompt_tokens: prompt_tokens, completion_tokens: completion_tokens, latency_ms: latency_ms}}

      {:ok, %{status: status, body: body}} ->
        latency_ms = native_to_ms(System.monotonic_time() - start_time)
        error = "Ollama returned #{status}: #{inspect(body)}"
        record_failure(message, latency_ms, error)
        {:error, error}

      {:error, reason} ->
        latency_ms = native_to_ms(System.monotonic_time() - start_time)
        error = "Could not reach Ollama: #{inspect(reason)}"
        record_failure(message, latency_ms, error)
        {:error, error}
    end
  end

  defp record_failure(message, latency_ms, error) do
    :telemetry.execute(
      [:ollama_wrapper, :request, :failure],
      %{latency_ms: latency_ms},
      %{model: @model, error: error}
    )

    Logger.error("[Ollama] #{latency_ms}ms | error: #{error}")

    OllamaWrapper.RequestStore.record(%{
      status: :error,
      model: @model,
      latency_ms: latency_ms,
      prompt_tokens: 0,
      completion_tokens: 0,
      timestamp: DateTime.utc_now(),
      message_preview: String.slice(message, 0, 100),
      error: error
    })
  end

  defp native_to_ms(native) do
    System.convert_time_unit(native, :native, :millisecond)
  end
end
