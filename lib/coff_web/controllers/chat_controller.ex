defmodule CoffWeb.ChatController do
  use CoffWeb, :controller

  def create(conn, %{"message" => message} = params) do
    system = Map.get(params, "system")

    case Coff.Ollama.chat(message, system) do
      {:ok, result} ->
        json(conn, result)

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: reason})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Missing required field: message"})
  end
end
