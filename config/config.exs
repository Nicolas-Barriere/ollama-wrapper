# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ollama_wrapper,
  generators: [timestamp_type: :utc_datetime],
  ecto_repos: [OllamaWrapper.Repo],
  ollama_base_url: "http://localhost:11434"

# Configure the endpoint
config :ollama_wrapper, OllamaWrapperWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: OllamaWrapperWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OllamaWrapper.PubSub,
  live_view: [signing_salt: "ov5xJXzb"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
