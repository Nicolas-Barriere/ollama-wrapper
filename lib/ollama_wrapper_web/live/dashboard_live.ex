defmodule OllamaWrapperWeb.DashboardLive do
  use OllamaWrapperWeb, :live_view

  alias OllamaWrapper.RequestStore

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OllamaWrapper.PubSub, RequestStore.topic())
    end

    {:ok,
     socket
     |> assign(:requests, RequestStore.recent())
     |> assign(:summary, RequestStore.summary())}
  end

  @impl true
  def handle_info({:new_request, _entry}, socket) do
    {:noreply,
     socket
     |> assign(:requests, RequestStore.recent())
     |> assign(:summary, RequestStore.summary())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Ollama Wrapper Dashboard</h1>

    <div class="stats">
      <div class="stat">
        <div class="stat-label">Total Requests</div>
        <div class="stat-value">{@summary.total_requests}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Successful</div>
        <div class="stat-value ok">{@summary.successful}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Failed</div>
        <div class="stat-value error">{@summary.failed}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Avg Latency</div>
        <div class="stat-value">{@summary.avg_latency_ms}ms</div>
      </div>
      <div class="stat">
        <div class="stat-label">Prompt Tokens</div>
        <div class="stat-value">{@summary.total_prompt_tokens}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Completion Tokens</div>
        <div class="stat-value">{@summary.total_completion_tokens}</div>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>Time</th>
          <th>Status</th>
          <th>Model</th>
          <th>Latency</th>
          <th>In</th>
          <th>Out</th>
          <th>Message</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={req <- @requests}>
          <td class="muted">{Calendar.strftime(req.timestamp, "%H:%M:%S")}</td>
          <td class={if req.status == :ok, do: "ok", else: "error"}>{req.status}</td>
          <td>{req.model}</td>
          <td>{req.latency_ms}ms</td>
          <td>{req.prompt_tokens}</td>
          <td>{req.completion_tokens}</td>
          <td class="muted">{req.message_preview}</td>
        </tr>
      </tbody>
    </table>
    """
  end
end
