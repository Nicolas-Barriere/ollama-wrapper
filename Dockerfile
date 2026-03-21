FROM elixir:1.16-alpine AS build

RUN apk add --no-cache build-base git

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN MIX_ENV=prod mix deps.get --only prod
RUN MIX_ENV=prod mix deps.compile

COPY config config
COPY lib lib
COPY priv priv

RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

# --- Runtime image ---
FROM alpine:3.19

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=build /app/_build/prod/rel/ollama_wrapper ./

ENV PHX_SERVER=true

EXPOSE 4000

CMD ["sh", "-c", "bin/ollama_wrapper eval 'OllamaWrapper.Release.migrate()' && bin/ollama_wrapper start"]
