defmodule OllamaWrapperWeb.ChatController do
  use OllamaWrapperWeb, :controller

  # Tool results follow-up: continue conversation after Brain executes tools
  def create(conn, %{"tool_results" => tool_results, "conversation_id" => conversation_id} = params) do
    model = Map.get(params, "model")
    stream = Map.get(params, "stream", true)
    think = Map.get(params, "think")
    tools = Map.get(params, "tools")

    if stream do
      stream_tool_response(conn, conversation_id, tool_results, model, think, tools)
    else
      case OllamaWrapper.Ollama.continue_after_tools(conversation_id, tool_results, model, nil, think, tools) do
        {:ok, result} ->
          json(conn, result)

        {:error, reason} ->
          conn
          |> put_status(:bad_gateway)
          |> json(%{error: reason})
      end
    end
  end

  def create(conn, %{"message" => message} = params) do
    system = Map.get(params, "system")
    model = Map.get(params, "model")
    stream = Map.get(params, "stream", true)
    think = Map.get(params, "think")
    conversation_id = Map.get(params, "conversation_id")
    tools = Map.get(params, "tools")

    if stream do
      stream_response(conn, message, system, model, think, conversation_id, tools)
    else
      case OllamaWrapper.Ollama.chat(message, system, model, nil, think, conversation_id, tools) do
        {:ok, result} ->
          json(conn, result)

        {:error, reason} ->
          conn
          |> put_status(:bad_gateway)
          |> json(%{error: reason})
      end
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Missing required field: message or tool_results"})
  end

  defp stream_response(conn, message, system, model, think, conversation_id, tools) do
    conn =
      conn
      |> put_resp_content_type("application/x-ndjson")
      |> send_chunked(200)

    on_chunk = build_chunk_handler(conn)
    OllamaWrapper.Ollama.chat(message, system, model, on_chunk, think, conversation_id, tools)
    conn
  end

  defp stream_tool_response(conn, conversation_id, tool_results, model, think, tools) do
    conn =
      conn
      |> put_resp_content_type("application/x-ndjson")
      |> send_chunked(200)

    on_chunk = build_chunk_handler(conn)
    OllamaWrapper.Ollama.continue_after_tools(conversation_id, tool_results, model, on_chunk, think, tools)
    conn
  end

  defp build_chunk_handler(conn) do
    fn
      {:thinking, text} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{thinking: text}) <> "\n")

      {:content, text} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{content: text}) <> "\n")

      {:tool_call, tool_call} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{tool_call: tool_call}) <> "\n")

      {:done, stats} ->
        Plug.Conn.chunk(conn, Jason.encode!(stats) <> "\n")

      {:error, reason} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{error: reason, done: true}) <> "\n")
    end
  end
end
