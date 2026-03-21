defmodule OllamaWrapper.RequestEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "request_events" do
    field :status, Ecto.Enum, values: [:ok, :error]
    field :model, :string
    field :latency_ms, :integer
    field :prompt_tokens, :integer
    field :completion_tokens, :integer
    field :thinking_duration_ms, :integer
    field :output_duration_ms, :integer
    field :prompt_eval_duration_ms, :integer
    field :load_duration_ms, :integer
    field :message, :string
    field :system_prompt, :string
    field :thinking, :string
    field :response, :string
    field :error, :string

    timestamps(type: :utc_datetime, inserted_at: :timestamp, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :status, :model, :latency_ms, :prompt_tokens, :completion_tokens,
      :thinking_duration_ms, :output_duration_ms, :prompt_eval_duration_ms, :load_duration_ms,
      :message, :system_prompt, :thinking, :response, :error
    ])
    |> validate_required([:status, :model, :latency_ms])
  end
end
