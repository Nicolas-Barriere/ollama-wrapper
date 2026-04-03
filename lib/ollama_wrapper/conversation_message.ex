defmodule OllamaWrapper.ConversationMessage do
  use Ecto.Schema

  @foreign_key_type :binary_id
  schema "conversation_messages" do
    field :conversation_id, :binary_id
    field :role, :string
    field :content, :string
    field :tool_calls, {:array, :map}

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
