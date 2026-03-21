defmodule OllamaWrapper.Repo do
  use Ecto.Repo,
    otp_app: :ollama_wrapper,
    adapter: Ecto.Adapters.Postgres
end
