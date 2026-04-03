defmodule OllamaWrapper.ConversationStore do
  import Ecto.Query

  alias OllamaWrapper.{Repo, Conversation, ConversationMessage}

  @default_max_turns 20

  def get_or_create(nil, system_prompt) do
    Repo.insert!(%Conversation{system_prompt: system_prompt})
  end

  def get_or_create(id, system_prompt) do
    case Repo.get(Conversation, id) do
      nil -> Repo.insert!(%Conversation{id: id, system_prompt: system_prompt})
      conv -> conv
    end
  end

  def history(conversation_id, max_turns \\ @default_max_turns) do
    conv = Repo.get!(Conversation, conversation_id)

    messages =
      Repo.all(
        from m in ConversationMessage,
          where: m.conversation_id == ^conversation_id,
          order_by: [desc: m.id],
          limit: ^(max_turns * 2),
          select: %{role: m.role, content: m.content, tool_calls: m.tool_calls}
      )
      |> Enum.reverse()
      |> Enum.map(fn m ->
        msg = %{role: m.role, content: m.content || ""}

        if m.tool_calls do
          Map.put(msg, :tool_calls, m.tool_calls)
        else
          msg
        end
      end)

    system =
      if conv.system_prompt, do: [%{role: "system", content: conv.system_prompt}], else: []

    system ++ messages
  end

  def save_turn(conversation_id, user_message, assistant_response) do
    Repo.insert!(%ConversationMessage{
      conversation_id: conversation_id,
      role: "user",
      content: user_message
    })

    Repo.insert!(%ConversationMessage{
      conversation_id: conversation_id,
      role: "assistant",
      content: assistant_response
    })
  end

  def save_assistant_tool_calls(conversation_id, tool_calls) do
    Repo.insert!(%ConversationMessage{
      conversation_id: conversation_id,
      role: "assistant",
      content: "",
      tool_calls: tool_calls
    })
  end

  def save_tool_results(conversation_id, tool_results) do
    Enum.each(tool_results, fn result ->
      Repo.insert!(%ConversationMessage{
        conversation_id: conversation_id,
        role: "tool",
        content: result["content"] || ""
      })
    end)
  end
end
