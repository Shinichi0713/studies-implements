import Foundation
import SwiftData

@Model
class HealthRecord {
    // CloudKit同期時のユニーク識別子
    @Attribute(.unique) var id: UUID
    var date: Date
    var bodyTemperature: Double?
    var weight: Double?
    var systolicBloodPressure: Int?
    var diastolicBloodPressure: Int?
    var heartRate: Int?
    var memo: String
    // 外部DBとの同期状態管理
    var lastSyncedAt: Date?
    var serverRecordId: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        bodyTemperature: Double? = nil,
        weight: Double? = nil,
        systolicBloodPressure: Int? = nil,
        diastolicBloodPressure: Int? = nil,
        heartRate: Int? = nil,
        memo: String = "",
        lastSyncedAt: Date? = nil,
        serverRecordId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.bodyTemperature = bodyTemperature
        self.weight = weight
        self.systolicBloodPressure = systolicBloodPressure
        self.diastolicBloodPressure = diastolicBloodPressure
        self.heartRate = heartRate
        self.memo = memo
        self.lastSyncedAt = lastSyncedAt
        self.serverRecordId = serverRecordId
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var summaryText: String {
        var parts: [String] = []
        if let temp = bodyTemperature {
            parts.append("体温: \(String(format: "%.1f", temp))°C")
        }
        if let hr = heartRate {
            parts.append("脈拍: \(hr) bpm")
        }
        if parts.isEmpty {
            return "メモのみ"
        }
        return parts.joined(separator: " / ")
    }

    var syncStatusText: String {
        if let lastSync = lastSyncedAt {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "同期済み: \(formatter.string(from: lastSync))"
        } else {
            return "未同期"
        }
    }
}

// API通信用のCodable構造体
extension HealthRecord {
    struct DTO: Codable {
        let id: UUID?
        let date: Date
        let bodyTemperature: Double?
        let weight: Double?
        let systolicBloodPressure: Int?
        let diastolicBloodPressure: Int?
        let heartRate: Int?
        let memo: String
    }

    func toDTO() -> DTO {
        DTO(
            id: id,
            date: date,
            bodyTemperature: bodyTemperature,
            weight: weight,
            systolicBloodPressure: systolicBloodPressure,
            diastolicBloodPressure: diastolicBloodPressure,
            heartRate: heartRate,
            memo: memo
        )
    }
}
