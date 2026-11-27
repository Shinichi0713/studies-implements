import Foundation

// ============================================================
// Sensor Data Store
// センサ読み取り履歴を管理し、統計情報を提供
// ============================================================

class SensorDataStore {
    private var readings: [SensorReading] = []
    private let queue = DispatchQueue(label: "sensor.datastore", attributes: .concurrent)
    private let maxHistory = 3600  // 最大1時間分（1秒間隔）

    /// 新しい読み取りデータを追加
    func add(_ reading: SensorReading) {
        queue.async(flags: .barrier) {
            self.readings.append(reading)
            if self.readings.count > self.maxHistory {
                self.readings.removeFirst(self.readings.count - self.maxHistory)
            }
        }
    }

    /// 全データを取得
    func allReadings() -> [SensorReading] {
        queue.sync {
            return self.readings
        }
    }

    /// 最新の読み取りデータ
    func latest() -> SensorReading? {
        queue.sync {
            return self.readings.last
        }
    }

    /// 直近N件を取得
    func last(_ count: Int) -> [SensorReading] {
        queue.sync {
            let start = max(0, self.readings.count - count)
            return Array(self.readings[start...])
        }
    }

    /// 統計情報
    func statistics() -> SensorStatistics {
        queue.sync {
            guard !self.readings.isEmpty else {
                return SensorStatistics()
            }
            let temps = self.readings.map { $0.temperature }
            let hums  = self.readings.map { $0.humidity }
            let press = self.readings.map { $0.pressure }

            return SensorStatistics(
                count: self.readings.count,
                tempMin: temps.min() ?? 0,
                tempMax: temps.max() ?? 0,
                tempAvg: temps.reduce(0, +) / Double(temps.count),
                humMin: hums.min() ?? 0,
                humMax: hums.max() ?? 0,
                humAvg: hums.reduce(0, +) / Double(hums.count),
                pressMin: press.min() ?? 0,
                pressMax: press.max() ?? 0,
                pressAvg: press.reduce(0, +) / Double(press.count)
            )
        }
    }

    /// JSON形式で全データを出力
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(allReadings()),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    /// CSV形式で出力
    func toCSV() -> String {
        var csv = "timestamp,temperature,humidity,pressure,altitude\n"
        let formatter = ISO8601DateFormatter()
        for r in allReadings() {
            csv += "\(formatter.string(from: r.timestamp)),\(r.temperature),\(r.humidity),\(r.pressure),\(r.altitude)\n"
        }
        return csv
    }
}

// MARK: - Statistics Model

struct SensorStatistics: Codable {
    let count: Int
    let tempMin, tempMax, tempAvg: Double
    let humMin, humMax, humAvg: Double
    let pressMin, pressMax, pressAvg: Double

    init(
        count: Int = 0,
        tempMin: Double = 0, tempMax: Double = 0, tempAvg: Double = 0,
        humMin: Double = 0, humMax: Double = 0, humAvg: Double = 0,
        pressMin: Double = 0, pressMax: Double = 0, pressAvg: Double = 0
    ) {
        self.count = count
        self.tempMin = tempMin; self.tempMax = tempMax; self.tempAvg = tempAvg
        self.humMin = humMin; self.humMax = humMax; self.humAvg = humAvg
        self.pressMin = pressMin; self.pressMax = pressMax; self.pressAvg = pressAvg
    }
}
