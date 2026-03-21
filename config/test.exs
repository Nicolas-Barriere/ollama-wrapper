import Config

config :ollama_wrapper, OllamaWrapper.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ollama_wrapper_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ollama_wrapper, OllamaWrapperWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qxlmkQC7l1XVPbTqTkfxL4nE8RBvFLIkNK++M1NhT63qZz01f8cw9TEVl+r4bv8b",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
