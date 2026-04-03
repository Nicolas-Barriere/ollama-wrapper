defmodule OllamaWrapper.Repo.Migrations.AddToolCallsToConversationMessages do
  use Ecto.Migration

  def change do
    alter table(:conversation_messages) do
      add :tool_calls, :jsonb
      modify :content, :text, null: true, from: {:text, null: false}
    end
  end
end
