defmodule OllamaWrapperWeb.Layouts do
  use OllamaWrapperWeb, :html

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="csrf-token" content={get_csrf_token()} />
      <title>Ollama Wrapper - Dashboard</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; background: #0d1117; color: #c9d1d9; padding: 24px; }
        h1 { color: #58a6ff; margin-bottom: 24px; font-size: 1.5rem; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 16px; margin-bottom: 32px; }
        .stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px; }
        .stat-label { color: #8b949e; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .stat-value { font-size: 1.5rem; font-weight: 600; color: #f0f6fc; margin-top: 4px; }
        table { width: 100%; border-collapse: collapse; background: #161b22; border-radius: 8px; overflow: hidden; }
        th { text-align: left; padding: 12px 16px; background: #21262d; color: #8b949e; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; }
        td { padding: 10px 16px; border-top: 1px solid #21262d; font-size: 0.875rem; }
        .ok { color: #3fb950; }
        .error { color: #f85149; }
        .muted { color: #8b949e; }
      </style>
    </head>
    <body>
      {@inner_content}
    </body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    {@inner_content}
    """
  end
end
