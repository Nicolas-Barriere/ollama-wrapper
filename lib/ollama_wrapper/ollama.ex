defmodule OllamaWrapper.Ollama do
  @base_url "http://localhost:11434"
  @model "qwen3:8b"

  def chat(message, system \\ nil) do
    messages =
      if system do
        [%{role: "system", content: system}, %{role: "user", content: message}]
      else
        [%{role: "user", content: message}]
      end

    body = %{model: @model, messages: messages, stream: false}

    case Req.post("#{@base_url}/api/chat", json: body, receive_timeout: 120_000) do
      {:ok, %{status: 200, body: %{"message" => %{"content" => content}, "done" => done}}} ->
        {:ok, %{response: content, model: @model, done: done}}

      {:ok, %{status: status, body: body}} ->
        {:error, "Ollama returned #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Could not reach Ollama: #{inspect(reason)}"}
    end
  end
end
