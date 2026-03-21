# Ollama Wrapper

A Phoenix-based observability wrapper for [Ollama](https://ollama.com). Proxies chat requests to a local Ollama instance, persists every request event to Postgres, and provides a real-time dashboard.

## Features

- **API proxy** — drop-in `/api/chat` endpoint compatible with OpenAI-style clients
- **Thinking capture** — streams the native Ollama API to separately record the model's chain-of-thought and final response
- **Per-request metrics** — latency, thinking duration, output duration, prompt/completion tokens, tok/s
- **Real-time dashboard** — LiveView dashboard with stats, searchable/filterable log table, and click-to-expand detail panel
- **Persistent storage** — all events stored in Postgres via Ecto
- **Docker-ready** — ships with `Dockerfile` and `docker-compose.yml` for local deployment

## Requirements

- [Ollama](https://ollama.com) running locally with a model pulled (default: `qwen3:8b`)
- Elixir 1.15+ / Erlang/OTP 26+
- PostgreSQL (or use Docker Compose which includes it)

## Quick start

```bash
# Install dependencies and create the database
mix setup

# Start the server
mix phx.server
```

- Dashboard: [localhost:4000/dashboard](http://localhost:4000/dashboard)
- API: `POST localhost:4000/api/chat`

## API

### POST /api/chat

```bash
curl -X POST http://localhost:4000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the capital of France?", "system": "Be concise."}'
```

**Request body**

| Field | Type | Required | Description |
|---|---|---|---|
| `message` | string | yes | User message |
| `system` | string | no | System prompt |

**Response**

```json
{
  "response": "Paris.",
  "thinking": "The user is asking about...",
  "model": "qwen3:8b",
  "prompt_tokens": 20,
  "completion_tokens": 145,
  "latency_ms": 8200,
  "thinking_duration_ms": 8150,
  "output_duration_ms": 50
}
```

## Docker

```bash
# Generate a secret key
mix phx.gen.secret

# Paste it in docker-compose.yml as SECRET_KEY_BASE, then:
docker compose up --build
```

Ollama stays on the host machine — Docker Desktop resolves `host.docker.internal` automatically on Mac and Windows. On Linux, `extra_hosts: host.docker.internal:host-gateway` is already set in the compose file.

## Configuration

| Environment variable | Default | Description |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama instance URL |
| `DATABASE_URL` | — | Postgres connection string (required in prod) |
| `SECRET_KEY_BASE` | — | Phoenix secret key (required in prod) |
| `PORT` | `4000` | HTTP port |

## Development

```bash
mix deps.get          # install dependencies
mix ecto.setup        # create DB and run migrations
mix phx.server        # start server with live reload

mix precommit         # compile, format, and test
```
