import Foundation
import NIO
import NIOHTTP1

// ============================================================
// HTTP Server - Sensor Dashboard
// NIOベースのHTTPサーバーでリアルタイムダッシュボードを提供
// ============================================================

var globalDataStore: SensorDataStore!

func startHTTPServer(dataStore: SensorDataStore) {
    globalDataStore = dataStore

    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer { try! group.syncShutdownGracefully() }

    let bootstrap = ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        .childChannelInitializer { channel in
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(HTTPHandler())
            }
        }
        .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

    do {
        let serverChannel = try bootstrap.bind(host: "0.0.0.0", port: 8080).wait()
        print("✅ HTTP Server started on http://\(serverChannel.localAddress!)")
        try serverChannel.closeFuture.wait()
    } catch {
        print("❌ Server failed to start: \(error)")
    }
}

// MARK: - HTTP Request Handler

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        guard case .head(let head) = reqPart else { return }

        let path = head.uri
        var responseBody: String = ""
        var contentType = "text/html; charset=utf-8"
        var status: HTTPResponseStatus = .ok

        switch path {
        case "/":
            responseBody = dashboardHTML()
        case "/api/data":
            contentType = "application/json"
            responseBody = globalDataStore.toJSON()
        case "/api/latest":
            contentType = "application/json"
            if let latest = globalDataStore.latest() {
                responseBody = latest.toJSON()
            } else {
                responseBody = "{}"
            }
        case "/api/stats":
            contentType = "application/json"
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(globalDataStore.statistics()),
               let json = String(data: data, encoding: .utf8) {
                responseBody = json
            }
        case "/api/csv":
            contentType = "text/csv; charset=utf-8"
            responseBody = globalDataStore.toCSV()
        default:
            status = .notFound
            responseBody = "<h1>404 Not Found</h1>"
        }

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: "\(responseBody.utf8.count)")
        headers.add(name: "Access-Control-Allow-Origin", value: "*")

        let responseHead = HTTPResponseHead(
            version: .init(major: 1, minor: 1),
            status: status,
            headers: headers
        )
        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(wrapOutboundOut(.body(.string(responseBody))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}

// MARK: - Dashboard HTML

func dashboardHTML() -> String {
    return """
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sensor Dashboard - BME280</title>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #0f172a;
                color: #e2e8f0;
                padding: 20px;
            }
            h1 {
                text-align: center;
                margin-bottom: 24px;
                font-size: 1.8rem;
                color: #60a5fa;
            }
            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 16px;
                margin-bottom: 24px;
            }
            .card {
                background: #1e293b;
                border-radius: 12px;
                padding: 20px;
                text-align: center;
                box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            }
            .card-icon {
                font-size: 2rem;
                margin-bottom: 8px;
            }
            .card-value {
                font-size: 2.4rem;
                font-weight: bold;
                margin: 8px 0;
            }
            .card-label {
                font-size: 0.9rem;
                color: #94a3b8;
            }
            .temp { color: #f87171; }
            .hum  { color: #60a5fa; }
            .pres { color: #34d399; }
            .alt  { color: #fbbf24; }
            .chart-container {
                background: #1e293b;
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 16px;
                height: 300px;
            }
            .status {
                text-align: center;
                color: #64748b;
                font-size: 0.85rem;
                margin-top: 8px;
            }
            .links {
                text-align: center;
                margin-top: 16px;
            }
            .links a {
                color: #60a5fa;
                margin: 0 12px;
                text-decoration: none;
            }
            .links a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        <h1>🌡️ Sensor Dashboard - BME280</h1>

        <div class="grid">
            <div class="card">
                <div class="card-icon">🌡️</div>
                <div class="card-value temp" id="tempVal">--</div>
                <div class="card-label">Temperature (°C)</div>
            </div>
            <div class="card">
                <div class="card-icon">💧</div>
                <div class="card-value hum" id="humVal">--</div>
                <div class="card-label">Humidity (%)</div>
            </div>
            <div class="card">
                <div class="card-icon">🌀</div>
                <div class="card-value pres" id="presVal">--</div>
                <div class="card-label">Pressure (hPa)</div>
            </div>
            <div class="card">
                <div class="card-icon">⛰️</div>
                <div class="card-value alt" id="altVal">--</div>
                <div class="card-label">Altitude (m)</div>
            </div>
        </div>

        <div class="chart-container">
            <canvas id="tempChart"></canvas>
        </div>
        <div class="chart-container">
            <canvas id="humChart"></canvas>
        </div>

        <div class="status" id="status">Updating...</div>

        <div class="links">
            <a href="/api/data" target="_blank">JSON API</a>
            <a href="/api/csv" target="_blank">CSV Export</a>
            <a href="/api/stats" target="_blank">Statistics</a>
        </div>

        <script>
            const maxPoints = 60;
            const tempChart = new Chart(document.getElementById('tempChart'), {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Temperature (°C)',
                        data: [],
                        borderColor: '#f87171',
                        backgroundColor: 'rgba(248,113,113,0.1)',
                        tension: 0.3,
                        fill: true,
                        pointRadius: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { labels: { color: '#e2e8f0' } } },
                    scales: {
                        x: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
                        y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } }
                    },
                    animation: false
                }
            });

            const humChart = new Chart(document.getElementById('humChart'), {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Humidity (%)',
                        data: [],
                        borderColor: '#60a5fa',
                        backgroundColor: 'rgba(96,165,250,0.1)',
                        tension: 0.3,
                        fill: true,
                        pointRadius: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { labels: { color: '#e2e8f0' } } },
                    scales: {
                        x: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } },
                        y: { ticks: { color: '#94a3b8' }, grid: { color: '#334155' } }
                    },
                    animation: false
                }
            });

            async function updateDashboard() {
                try {
                    const res = await fetch('/api/data');
                    const data = await res.json();
                    if (data.length === 0) return;

                    const latest = data[data.length - 1];
                    document.getElementById('tempVal').textContent = latest.temperature.toFixed(2);
                    document.getElementById('humVal').textContent = latest.humidity.toFixed(1);
                    document.getElementById('presVal').textContent = latest.pressure.toFixed(1);
                    document.getElementById('altVal').textContent = latest.altitude.toFixed(1);

                    const recent = data.slice(-maxPoints);
                    const labels = recent.map((_, i) => i);

                    tempChart.data.labels = labels;
                    tempChart.data.datasets[0].data = recent.map(d => d.temperature);
                    tempChart.update();

                    humChart.data.labels = labels;
                    humChart.data.datasets[0].data = recent.map(d => d.humidity);
                    humChart.update();

                    document.getElementById('status').textContent =
                        'Last updated: ' + new Date().toLocaleTimeString() +
                        ' | Total readings: ' + data.length;
                } catch (e) {
                    document.getElementById('status').textContent = 'Update failed: ' + e.message;
                }
            }

            updateDashboard();
            setInterval(updateDashboard, 1000);
        </script>
    </body>
    </html>
    """
}
