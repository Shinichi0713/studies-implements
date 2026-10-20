import Foundation
import SwiftData

@Model
class HealthRecord {
    var date: Date
    var bodyTemperature: Double?
    var weight: Double?
    var systolicBloodPressure: Int?
    var diastolicBloodPressure: Int?
    var heartRate: Int?
    var memo: String

    init(
        date: Date = Date(),
        bodyTemperature: Double? = nil,
        weight: Double? = nil,
        systolicBloodPressure: Int? = nil,
        diastolicBloodPressure: Int? = nil,
        heartRate: Int? = nil,
        memo: String = ""
    ) {
        self.date = date
        self.bodyTemperature = bodyTemperature
        self.weight = weight
        self.systolicBloodPressure = systolicBloodPressure
        self.diastolicBloodPressure = diastolicBloodPressure
        self.heartRate = heartRate
        self.memo = memo
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
}
