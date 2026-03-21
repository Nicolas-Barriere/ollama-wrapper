defmodule OllamaWrapperWeb.DashboardLive do
  use OllamaWrapperWeb, :live_view

  alias OllamaWrapper.RequestStore

  @default_filters %{search: "", status: "", model: ""}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OllamaWrapper.PubSub, RequestStore.topic())
    end

    filters = @default_filters

    {:ok,
     socket
     |> assign(:filters, filters)
     |> assign(:models, RequestStore.models())
     |> assign(:requests, RequestStore.recent(50, filters))
     |> assign(:summary, RequestStore.summary())
     |> assign(:selected_id, nil)}
  end

  @impl true
  def handle_info({:new_request, _entry}, socket) do
    {:noreply,
     socket
     |> assign(:models, RequestStore.models())
     |> assign(:requests, RequestStore.recent(50, socket.assigns.filters))
     |> assign(:summary, RequestStore.summary())}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = %{
      search: Map.get(params, "search", ""),
      status: Map.get(params, "status", ""),
      model: Map.get(params, "model", "")
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:selected_id, nil)
     |> assign(:requests, RequestStore.recent(50, filters))}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_id = if socket.assigns.selected_id == id, do: nil, else: id
    {:noreply, assign(socket, :selected_id, selected_id)}
  end

  defp selected_request(requests, id) do
    Enum.find(requests, &(&1.id == id))
  end

  defp tokens_per_sec(req) do
    gen_ms = (req.thinking_duration_ms || 0) + (req.output_duration_ms || 0)
    if gen_ms > 0, do: Float.round(req.completion_tokens / (gen_ms / 1000), 1), else: nil
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
        <div class="stat-label">Avg tok/s</div>
        <div class="stat-value">{@summary.avg_tokens_per_sec}</div>
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

    <form phx-change="filter" class="filters">
      <input
        type="text"
        name="search"
        value={@filters.search}
        placeholder="Search messages and responses..."
        class="filter-search"
        phx-debounce="300"
      />
      <select name="status" class="filter-select">
        <option value="" selected={@filters.status == ""}>All statuses</option>
        <option value="ok" selected={@filters.status == "ok"}>OK</option>
        <option value="error" selected={@filters.status == "error"}>Error</option>
      </select>
      <select name="model" class="filter-select">
        <option value="" selected={@filters.model == ""}>All models</option>
        <option :for={m <- @models} value={m} selected={@filters.model == m}>{m}</option>
      </select>
    </form>

    <table>
      <thead>
        <tr>
          <th>Time</th>
          <th>Status</th>
          <th>Model</th>
          <th>Total</th>
          <th>Think</th>
          <th>Output</th>
          <th>In</th>
          <th>Out</th>
          <th>tok/s</th>
          <th>Message</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={req <- @requests}
          phx-click="select"
          phx-value-id={req.id}
          class={if @selected_id == req.id, do: "selected", else: ""}
          style="cursor: pointer;"
        >
          <td class="muted">{Calendar.strftime(req.timestamp, "%H:%M:%S")}</td>
          <td class={if req.status == :ok, do: "ok", else: "error"}>{req.status}</td>
          <td>{req.model}</td>
          <td>{req.latency_ms}ms</td>
          <td class="muted">{req.thinking_duration_ms}ms</td>
          <td class="muted">{req.output_duration_ms}ms</td>
          <td>{req.prompt_tokens}</td>
          <td>{req.completion_tokens}</td>
          <td>{tokens_per_sec(req)}</td>
          <td class="muted">{String.slice(req.message || "", 0, 100)}</td>
        </tr>
      </tbody>
    </table>

    <div :if={@selected_id} class="detail-panel">
      <% req = selected_request(@requests, @selected_id) %>
      <div :if={req}>
        <h2>Request detail — {Calendar.strftime(req.timestamp, "%H:%M:%S")}</h2>

        <div class="detail-section">
          <div class="detail-label">Input</div>
          <pre class="detail-content">{req.message}</pre>
        </div>

        <div :if={req.system_prompt} class="detail-section">
          <div class="detail-label">System prompt</div>
          <pre class="detail-content">{req.system_prompt}</pre>
        </div>

        <div :if={req.thinking} class="detail-section">
          <div class="detail-label">Thinking ({req.thinking_duration_ms}ms)</div>
          <pre class="detail-content muted">{req.thinking}</pre>
        </div>

        <div :if={req.response} class="detail-section">
          <div class="detail-label">Response ({req.output_duration_ms}ms)</div>
          <pre class="detail-content">{req.response}</pre>
        </div>

        <div :if={req.error} class="detail-section">
          <div class="detail-label">Error</div>
          <pre class="detail-content error">{req.error}</pre>
        </div>
      </div>
    </div>
    """
  end
end
