import Foundation
import UserNotifications
import SwiftData

// ローカル通知の管理を行うシングルトン
class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current)

    private init() {}

    // MARK: - 通知許可をリクエスト
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            }
            print(granted ? "通知許可: 許可済み" : "通知許可: 拒否")
        }
    }

    // MARK: - 通知の許可状態を確認
    func checkAuthorizationStatus() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - リマインダーを通知としてスケジュール
    func scheduleNotification(for reminder: HealthReminder) {
        guard reminder.isEnabled else { return }

        // 既存の通知を削除してから再スケジュール
        removeNotification(for: reminder)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.notes.isEmpty ? reminder.scheduleDescription : reminder.notes
        content.sound = .default
        content.userInfo = ["reminderId": reminder.id.uuidString]

        let trigger = createTrigger(for: reminder)
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                print("通知をスケジュール: \(reminder.title) at \(reminder.formattedTime)")
            }
        }
    }

    // MARK: - リマインダーの通知を削除
    func removeNotification(for reminder: HealthReminder) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }

    // MARK: - 全通知を削除
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - トリガーの作成
    private func createTrigger(for reminder: HealthReminder) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminder.time)

        switch reminder.repeatInterval {
        case .none:
            // 一度だけ: 今日の指定時刻
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.time)
            // 過ぎていたら明日にする
            if let scheduledDate = calendar.date(from: components),
               scheduledDate < Date() {
                components.day! += 1
            }
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        case .daily:
            return UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)

        case .weekdays:
            // 月〜金は個別に5つの通知をスケジュール
            let weekdaySymbols = [2, 3, 4, 5, 6] // 月〜金（Calendarのweekday: 日=1, 月=2...）
            for (index, weekday) in weekdaySymbols.enumerated() {
                var components = timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(reminder.id.uuidString)_weekday_\(index)",
                    content: createContent(for: reminder),
                    trigger: trigger
                )
                center.add(request)
            }
            // ダミーを返す（実際は上で個別に登録済み）
            return UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)

        case .weekends:
            // 土日も個別に
            let weekendSymbols = [7, 1] // 土=7, 日=1
            for (index, weekday) in weekendSymbols.enumerated() {
                var components = timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(reminder.id.uuidString)_weekend_\(index)",
                    content: createContent(for: reminder),
                    trigger: trigger
                )
                center.add(request)
            }
            return UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)

        case .weekly:
            var components = timeComponents
            components.weekday = calendar.component(.weekday, from: reminder.time)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }

    private func createContent(for reminder: HealthReminder) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.notes.isEmpty ? reminder.scheduleDescription : reminder.notes
        content.sound = .default
        content.userInfo = ["reminderId": reminder.id.uuidString]
        return content
    }

    // MARK: - 全リマインダーを再スケジュール（アプリ起動時など）
    func rescheduleAllReminders(from context: ModelContext) {
        let descriptor = FetchDescriptor<HealthReminder>(
            predicate: #predicate { $0.isEnabled == true }
        )
        guard let reminders = try? context.fetch(descriptor) else { return }

        for reminder in reminders {
            scheduleNotification(for: reminder)
        }
    }
}
