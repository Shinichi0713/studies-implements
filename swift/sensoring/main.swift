import Foundation
import NIO
import NIOHTTP1

// ============================================================
// SensorDashboard - Raspberry Pi I2C Sensor Data Visualization
// ============================================================
// BME280センサからI2Cで温度・湿度・気圧を取得し、
// HTTPサーバーでリアルタイムダッシュボードを提供します。
//
// 実行方法:
//   sudo swift run SensorApp
//
// ブラウザで http://ラズパイのIP:8080 にアクセス
// ============================================================

// グローバルデータストア
var sensorDataStore = SensorDataStore()

// メインエントリポイント
let i2cBus = I2CBus(busNumber: 1)
let bme280 = BME280(i2c: i2cBus, address: 0x76)

// センサ初期化
if bme280.initialize() {
    print("✅ BME280 initialized successfully")
} else {
    print("⚠️ BME280 not found. Running in simulation mode.")
}

// HTTPサーバーを別スレッドで起動
let serverThread = Thread {
    startHTTPServer(dataStore: sensorDataStore)
}
serverThread.start()

// メインループ: 1秒ごとにセンサを読んでデータストアに保存
print("📊 Starting sensor read loop...")
print("🌐 Open http://<raspberry-pi-ip>:8080 in your browser")
print("Press Ctrl+C to stop")
print("")

while true {
    let reading: SensorReading
    if bme280.isInitialized {
        reading = bme280.read()
    } else {
        // シミュレーションモード
        reading = SensorReading.simulated()
    }
    sensorDataStore.add(reading)

    print(String(
        format: "🌡 %.2f°C  |  💧 %.1f%%  |  🌀 %.1f hPa",
        reading.temperature,
        reading.humidity,
        reading.pressure
    ))

    Thread.sleep(forTimeInterval: 1.0)
}
