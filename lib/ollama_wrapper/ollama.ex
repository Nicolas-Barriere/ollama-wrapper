defmodule OllamaWrapper.Ollama do
  require Logger

  @model "qwen3:8b"

  defp base_url do
    Application.get_env(:ollama_wrapper, :ollama_base_url, "http://localhost:11434")
  end

  def chat(message, system \\ nil) do
    messages = build_messages(message, system)
    payload = %{model: @model, messages: messages, stream: true}
    start_ms = now_ms()

    {:ok, state_pid} =
      Agent.start_link(fn ->
        %{
          thinking: [],
          content: [],
          thinking_end_ms: nil,
          prompt_tokens: 0,
          completion_tokens: 0,
          prompt_eval_duration_ns: 0,
          load_duration_ns: 0
        }
      end)

    req_result =
      Req.post("#{base_url()}/api/chat",
        json: payload,
        receive_timeout: 120_000,
        into: fn {:data, chunk}, acc ->
          Agent.update(state_pid, &process_chunk(chunk, &1, start_ms))
          {:cont, acc}
        end
      )

    result = Agent.get(state_pid, & &1)
    Agent.stop(state_pid)

    case req_result do
      {:ok, _response} ->
        build_success(result, message, system, start_ms)

      {:error, reason} ->
        error = "Could not reach Ollama: #{inspect(reason)}"
        record_failure(message, system, now_ms() - start_ms, error)
        {:error, error}
    end
  end

  defp build_success(result, message, system, start_ms) do
    total_ms = now_ms() - start_ms
    thinking_text = result.thinking |> Enum.reverse() |> IO.iodata_to_binary()
    content_text = result.content |> Enum.reverse() |> IO.iodata_to_binary()

    thinking_end_ms = result.thinking_end_ms || total_ms
    thinking_duration_ms = thinking_end_ms
    output_duration_ms = total_ms - thinking_end_ms

    prompt_eval_ms = div(result.prompt_eval_duration_ns, 1_000_000)
    load_ms = div(result.load_duration_ns, 1_000_000)

    :telemetry.execute(
      [:ollama_wrapper, :request, :success],
      %{
        latency_ms: total_ms,
        thinking_duration_ms: thinking_duration_ms,
        output_duration_ms: output_duration_ms
      },
      %{model: @model}
    )

    Logger.info(
      "[Ollama] #{total_ms}ms (think:#{thinking_duration_ms}ms out:#{output_duration_ms}ms) | in:#{result.prompt_tokens} out:#{result.completion_tokens} tokens | model:#{@model}"
    )

    OllamaWrapper.RequestStore.record(%{
      status: :ok,
      model: @model,
      latency_ms: total_ms,
      thinking_duration_ms: thinking_duration_ms,
      output_duration_ms: output_duration_ms,
      prompt_eval_duration_ms: prompt_eval_ms,
      load_duration_ms: load_ms,
      prompt_tokens: result.prompt_tokens,
      completion_tokens: result.completion_tokens,
      message: message,
      system_prompt: system,
      thinking: thinking_text,
      response: content_text
    })

    {:ok,
     %{
       response: content_text,
       thinking: thinking_text,
       model: @model,
       prompt_tokens: result.prompt_tokens,
       completion_tokens: result.completion_tokens,
       latency_ms: total_ms,
       thinking_duration_ms: thinking_duration_ms,
       output_duration_ms: output_duration_ms
     }}
  end

  defp process_chunk(chunk, state, start_ms) do
    chunk
    |> String.split("\n", trim: true)
    |> Enum.reduce(state, &process_line(&1, &2, start_ms))
  end

  defp process_line(line, state, start_ms) do
    case Jason.decode(line) do
      {:ok, data} -> process_data(data, state, start_ms)
      _ -> state
    end
  end

  defp process_data(%{"done" => true} = data, state, _start_ms) do
    %{
      state
      | prompt_tokens: Map.get(data, "prompt_eval_count", state.prompt_tokens),
        completion_tokens: Map.get(data, "eval_count", state.completion_tokens),
        prompt_eval_duration_ns: Map.get(data, "prompt_eval_duration", state.prompt_eval_duration_ns),
        load_duration_ns: Map.get(data, "load_duration", state.load_duration_ns)
    }
  end

  defp process_data(%{"message" => msg}, state, start_ms) do
    thinking_chunk = Map.get(msg, "thinking", "")
    content_chunk = Map.get(msg, "content", "")

    state
    |> append_thinking(thinking_chunk)
    |> append_content(content_chunk, start_ms)
  end

  defp process_data(_data, state, _start_ms), do: state

  defp append_thinking(state, ""), do: state
  defp append_thinking(state, chunk), do: %{state | thinking: [chunk | state.thinking]}

  defp append_content(state, "", _start_ms), do: state

  defp append_content(%{thinking_end_ms: nil} = state, chunk, start_ms) do
    %{state | content: [chunk | state.content], thinking_end_ms: now_ms() - start_ms}
  end

  defp append_content(state, chunk, _start_ms) do
    %{state | content: [chunk | state.content]}
  end

  defp record_failure(message, system, latency_ms, error) do
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
      thinking_duration_ms: 0,
      output_duration_ms: 0,
      prompt_eval_duration_ms: 0,
      load_duration_ms: 0,
      prompt_tokens: 0,
      completion_tokens: 0,
      message: message,
      system_prompt: system,
      error: error
    })
  end

  defp build_messages(message, nil), do: [%{role: "user", content: message}]

  defp build_messages(message, system) do
    [%{role: "system", content: system}, %{role: "user", content: message}]
  end

  defp now_ms, do: System.monotonic_time(:millisecond)
end
