defmodule OllamaWrapper.Repo.Migrations.CreateRequestEvents do
  use Ecto.Migration

  def change do
    create table(:request_events) do
      add :status, :string, null: false
      add :model, :string, null: false
      add :latency_ms, :integer, null: false
      add :prompt_tokens, :integer, default: 0
      add :completion_tokens, :integer, default: 0
      add :message, :text
      add :response, :text
      add :error, :text

      timestamps(type: :utc_datetime, inserted_at: :timestamp, updated_at: false)
    end

    create index(:request_events, [:timestamp])
    create index(:request_events, [:status])
  end
end
