defmodule OllamaWrapperWeb.ChatController do
  use OllamaWrapperWeb, :controller

  def create(conn, %{"message" => message} = params) do
    system = Map.get(params, "system")
    model = Map.get(params, "model")
    stream = Map.get(params, "stream", true)
    think = Map.get(params, "think")

    if stream do
      stream_response(conn, message, system, model, think)
    else
      case OllamaWrapper.Ollama.chat(message, system, model, nil, think) do
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
    |> json(%{error: "Missing required field: message"})
  end

  defp stream_response(conn, message, system, model, think) do
    conn =
      conn
      |> put_resp_content_type("application/x-ndjson")
      |> send_chunked(200)

    on_chunk = fn
      {:thinking, text} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{thinking: text}) <> "\n")

      {:content, text} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{content: text}) <> "\n")

      {:done, stats} ->
        Plug.Conn.chunk(conn, Jason.encode!(stats) <> "\n")

      {:error, reason} ->
        Plug.Conn.chunk(conn, Jason.encode!(%{error: reason, done: true}) <> "\n")
    end

    OllamaWrapper.Ollama.chat(message, system, model, on_chunk, think)
    conn
  end
end
