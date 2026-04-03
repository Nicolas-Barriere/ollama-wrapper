defmodule OllamaWrapper.Conversation do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "conversations" do
    field :system_prompt, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
