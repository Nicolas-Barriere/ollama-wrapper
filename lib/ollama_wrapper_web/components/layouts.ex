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
        .filters { display: flex; gap: 12px; margin-bottom: 16px; }
        .filter-search { flex: 1; background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 8px 12px; color: #c9d1d9; font-size: 0.875rem; outline: none; }
        .filter-search:focus { border-color: #58a6ff; }
        .filter-select { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 8px 12px; color: #c9d1d9; font-size: 0.875rem; outline: none; cursor: pointer; }
        .filter-select:focus { border-color: #58a6ff; }
        tr.selected td { background: #1c2128; }
        tr:hover td { background: #1c2128; }
        .detail-panel { margin-top: 24px; background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 24px; }
        .detail-panel h2 { color: #58a6ff; font-size: 1rem; margin-bottom: 20px; }
        .detail-section { margin-bottom: 20px; }
        .detail-label { color: #8b949e; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 8px; }
        .detail-content { white-space: pre-wrap; word-break: break-word; font-family: monospace; font-size: 0.875rem; background: #0d1117; border: 1px solid #21262d; border-radius: 6px; padding: 12px; line-height: 1.6; }

        /* Charts */
        .charts-section { margin-bottom: 32px; }
        .chart-controls { display: flex; align-items: center; gap: 16px; margin-bottom: 16px; }
        .btn-group { display: flex; gap: 4px; background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 3px; }
        .btn { background: transparent; border: none; border-radius: 4px; padding: 5px 12px; color: #8b949e; font-size: 0.8rem; cursor: pointer; transition: background 0.15s, color 0.15s; }
        .btn:hover { color: #c9d1d9; background: #21262d; }
        .btn-active { background: #21262d; color: #f0f6fc; }
        .charts-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        @media (max-width: 768px) { .charts-grid { grid-template-columns: 1fr; } }
        .chart-panel { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px; }
        .chart-title { color: #8b949e; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 12px; }
        .chart-panel canvas { height: 200px !important; }
      </style>
    </head>
    <body>
      {@inner_content}
      <script src="/assets/phoenix.min.js"></script>
      <script src="/assets/phoenix_live_view.min.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
      <script>
        const Hooks = {};

        Hooks.Charts = {
          mounted() {
            this.charts = null;
            this.initCharts();
          },

          updated() {
            if (!this.charts) {
              this.initCharts();
            } else {
              this.updateChartsData(this.getData());
            }
          },

          getData() {
            try {
              return JSON.parse(this.el.dataset.chart);
            } catch(e) {
              return { labels: [], successful: [], failed: [], avg_tok_sec: [] };
            }
          },

          initCharts() {
            const data = this.getData();
            const gridColor = '#21262d';
            const tickColor = '#8b949e';

            const axisDefaults = {
              ticks: { color: tickColor, maxTicksLimit: 8 },
              grid: { color: gridColor }
            };

            this.charts = {};

            this.charts.requests = new Chart(
              this.el.querySelector('#requests-canvas'),
              {
                type: 'bar',
                data: {
                  labels: data.labels,
                  datasets: [
                    {
                      label: 'Success',
                      data: data.successful,
                      backgroundColor: '#3fb95066',
                      borderColor: '#3fb950',
                      borderWidth: 1
                    },
                    {
                      label: 'Failed',
                      data: data.failed,
                      backgroundColor: '#f8514966',
                      borderColor: '#f85149',
                      borderWidth: 1
                    }
                  ]
                },
                options: {
                  responsive: true,
                  maintainAspectRatio: false,
                  animation: false,
                  plugins: {
                    legend: { labels: { color: tickColor, boxWidth: 12, padding: 12 } }
                  },
                  scales: {
                    x: { ...axisDefaults, stacked: true, ticks: { ...axisDefaults.ticks, maxRotation: 45 } },
                    y: { ...axisDefaults, stacked: true, beginAtZero: true }
                  }
                }
              }
            );

            this.charts.tokSec = new Chart(
              this.el.querySelector('#tok-sec-canvas'),
              {
                type: 'line',
                data: {
                  labels: data.labels,
                  datasets: [{
                    label: 'Avg tok/sec',
                    data: data.avg_tok_sec,
                    borderColor: '#58a6ff',
                    backgroundColor: '#58a6ff18',
                    fill: true,
                    tension: 0.3,
                    pointRadius: 3,
                    pointHoverRadius: 5,
                    spanGaps: true
                  }]
                },
                options: {
                  responsive: true,
                  maintainAspectRatio: false,
                  animation: false,
                  plugins: {
                    legend: { display: false }
                  },
                  scales: {
                    x: { ...axisDefaults, ticks: { ...axisDefaults.ticks, maxRotation: 45 } },
                    y: { ...axisDefaults, beginAtZero: true }
                  }
                }
              }
            );
          },

          updateChartsData(data) {
            this.charts.requests.data.labels = data.labels;
            this.charts.requests.data.datasets[0].data = data.successful;
            this.charts.requests.data.datasets[1].data = data.failed;
            this.charts.requests.update('none');

            this.charts.tokSec.data.labels = data.labels;
            this.charts.tokSec.data.datasets[0].data = data.avg_tok_sec;
            this.charts.tokSec.update('none');
          }
        };

        let liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
          params: { _csrf_token: document.querySelector("meta[name='csrf-token']").getAttribute("content") },
          hooks: Hooks
        })
        liveSocket.connect()
      </script>
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
