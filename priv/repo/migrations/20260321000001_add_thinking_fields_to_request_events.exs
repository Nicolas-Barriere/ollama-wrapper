defmodule OllamaWrapper.Repo.Migrations.AddThinkingFieldsToRequestEvents do
  use Ecto.Migration

  def change do
    alter table(:request_events) do
      add :thinking, :text
      add :system_prompt, :text
      add :thinking_duration_ms, :integer
      add :output_duration_ms, :integer
      add :prompt_eval_duration_ms, :integer
      add :load_duration_ms, :integer
    end
  end
end
