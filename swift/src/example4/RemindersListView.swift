import SwiftUI
import SwiftData

struct RemindersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthReminder.time) private var reminders: [HealthReminder]

    @State private var showingAddSheet = false
    @State private var editingReminder: HealthReminder?

    var body: some View {
        NavigationStack {
            List {
                if reminders.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("リマインダーがありません")
                                .foregroundStyle(.secondary)
                            Text("毎日の測定を忘れないように通知を設定しましょう")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section {
                        ForEach(reminders) { reminder in
                            ReminderRowView(reminder: reminder)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingReminder = reminder
                                }
                        }
                        .onDelete(perform: deleteReminders)
                    } header: {
                        Text("有効なリマインダー")
                    } footer: {
                        Text("タップで編集、スワイプで削除できます。通知を受け取るには設定アプリで通知を許可してください。")
                    }
                }

                // 通知設定ガイド
                Section {
                    NavigationLink(destination: NotificationGuideView()) {
                        Label("通知設定ガイド", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("リマインダー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddReminderView()
            }
            .sheet(item: $editingReminder) { reminder in
                AddReminderView(reminder: reminder)
            }
        }
    }

    private func deleteReminders(offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            NotificationManager.shared.removeNotification(for: reminder)
            modelContext.delete(reminder)
        }
    }
}

// MARK: - リマインダー行ビュー
struct ReminderRowView: View {
    let reminder: HealthReminder

    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(reminder.isEnabled ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: reminder.reminderType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(reminder.isEnabled ? .accent : .gray)
            }

            // テキスト情報
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .foregroundStyle(reminder.isEnabled ? .primary : .secondary)
                Text(reminder.scheduleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            // ON/OFF トグル
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { newValue in
                    reminder.isEnabled = newValue
                    if newValue {
                        NotificationManager.shared.scheduleNotification(for: reminder)
                    } else {
                        NotificationManager.shared.removeNotification(for: reminder)
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .opacity(reminder.isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - 通知設定ガイド
struct NotificationGuideView: View {
    var body: some View {
        List {
            Section("通知が届かない場合") {
                Label("設定アプリ > 通知 > 体調管理 で通知を許可してください", systemImage: "1.circle")
                Label("iOSの「集中モード」がオフになっているか確認してください", systemImage: "2.circle")
                Label("iPhoneのサイレントスイッチ（物理スイッチ）がオフになっていないか確認してください", systemImage: "3.circle")
            }

            Section("リマインダーの使い方") {
                Label("毎日の体温・体重測定を忘れずに記録できます", systemImage: "checkmark")
                Label("服薬時間のリマインダーも設定可能です", systemImage: "checkmark")
                Label("繰り返し設定で毎日・平日・週末を選べます", systemImage: "checkmark")
            }
        }
        .navigationTitle("通知設定ガイド")
    }
}

#Preview {
    RemindersListView()
        .modelContainer(for: [HealthRecord.self, HealthReminder.self], inMemory: true)
}
