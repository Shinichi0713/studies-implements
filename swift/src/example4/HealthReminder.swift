import Foundation
import SwiftData

// リマインダーの種類
enum ReminderType: String, Codable, CaseIterable {
    case bodyTemperature = "体温測定"
    case weight = "体重測定"
    case bloodPressure = "血圧測定"
    case medication = "服薬"
    case custom = "カスタム"

    var icon: String {
        switch self {
        case .bodyTemperature: return "thermometer"
        case .weight: return "scalemass"
        case .bloodPressure: return "heart.fill"
        case .medication: return "pills.fill"
        case .custom: return "bell.fill"
        }
    }

    var defaultTitle: String {
        return self.rawValue
    }
}

// 繰り返し間隔
enum RepeatInterval: String, Codable, CaseIterable {
    case none = "繰り返しなし"
    case daily = "毎日"
    case weekdays = "平日（月〜金）"
    case weekends = "週末（土日）"
    case weekly = "毎週"

    var calendarComponent: Calendar.Component? {
        switch self {
        case .daily, .weekdays, .weekends: return .day
        case .weekly: return .weekOfYear
        case .none: return nil
        }
    }
}

@Model
class HealthReminder {
    @Attribute(.unique) var id: UUID
    var title: String
    var reminderTypeRaw: String
    var time: Date          // 通知時刻（DateComponentsから時分を抽出）
    var repeatIntervalRaw: String
    var isEnabled: Bool
    var notes: String
    var createdAt: Date

    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRaw) ?? .custom }
        set { reminderTypeRaw = newValue.rawValue }
    }

    var repeatInterval: RepeatInterval {
        get { RepeatInterval(rawValue: repeatIntervalRaw) ?? .none }
        set { repeatIntervalRaw = newValue.rawValue }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    var scheduleDescription: String {
        if repeatInterval == .none {
            return "今日 \(formattedTime)"
        }
        return "\(repeatInterval.rawValue) \(formattedTime)"
    }

    init(
        id: UUID = UUID(),
        title: String,
        reminderType: ReminderType = .custom,
        time: Date,
        repeatInterval: RepeatInterval = .daily,
        isEnabled: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.reminderTypeRaw = reminderType.rawValue
        self.time = time
        self.repeatIntervalRaw = repeatInterval.rawValue
        self.isEnabled = isEnabled
        self.notes = notes
        self.createdAt = Date()
    }
}
