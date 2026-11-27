import Foundation

// ============================================================
// Sensor Reading Data Model
// ============================================================

struct SensorReading: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let temperature: Double    // Celsius
    let humidity: Double     // %
    let pressure: Double     // hPa
    let altitude: Double     // meters

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        temperature: Double,
        humidity: Double,
        pressure: Double,
        altitude: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.temperature = temperature
        self.humidity = humidity
        self.pressure = pressure
        self.altitude = altitude
    }

    /// シミュレーション用: ランダムな値を生成
    static func simulated() -> SensorReading {
        let baseTemp = 24.0
        let baseHum = 45.0
        let basePres = 1013.0
        return SensorReading(
            temperature: baseTemp + Double.random(in: -2.0...2.0),
            humidity: baseHum + Double.random(in: -5.0...5.0),
            pressure: basePres + Double.random(in: -10.0...10.0),
            altitude: 15.0 + Double.random(in: -1.0...1.0)
        )
    }

    /// JSON形式で出力
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    /// タイムスタンプを日本時間でフォーマット
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: timestamp)
    }
}
