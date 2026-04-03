defmodule OllamaWrapper.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :system_prompt, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create table(:conversation_messages) do
      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false

      add :role, :string, null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:conversation_messages, [:conversation_id, :inserted_at])
  end
end
