import SwiftUI

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var reminder: HealthReminder?  // nilなら新規、あれば編集

    @State private var title = ""
    @State private var selectedType: ReminderType = .bodyTemperature
    @State private var time = Date()
    @State private var selectedRepeat: RepeatInterval = .daily
    @State private var notes = ""
    @State private var isEnabled = true

    private var isEditing: Bool { reminder != nil }

    init(reminder: HealthReminder? = nil) {
        self.reminder = reminder
        if let reminder = reminder {
            _title = State(initialValue: reminder.title)
            _selectedType = State(initialValue: reminder.reminderType)
            _time = State(initialValue: reminder.time)
            _selectedRepeat = State(initialValue: reminder.repeatInterval)
            _notes = State(initialValue: reminder.notes)
            _isEnabled = State(initialValue: reminder.isEnabled)
        } else {
            // デフォルトで朝7:00に設定
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            let defaultTime = Calendar.current.date(from: components) ?? Date()
            _time = State(initialValue: defaultTime)
            _title = State(initialValue: ReminderType.bodyTemperature.defaultTitle)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("タイトル", text: $title)

                    Picker("種類", selection: $selectedType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .onChange(of: selectedType) { _, newType in
                        if !isEditing {
                            title = newType.defaultTitle
                        }
                    }
                }

                Section("時間") {
                    DatePicker("通知時刻",
                               selection: $time,
                               displayedComponents: .hourAndMinute)
                }

                Section("繰り返し") {
                    Picker("間隔", selection: $selectedRepeat) {
                        ForEach(RepeatInterval.allCases, id: \.self) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("メモ（任意）") {
                    TextField("例: 朝食前に測定", text: $notes)
                }

                if isEditing {
                    Section {
                        Toggle("リマインダーを有効にする", isOn: $isEnabled)
                    }
                }

                // プレビュー
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: selectedType.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(.accent)
                            Text(title.isEmpty ? "タイトル" : title)
                                .font(.headline)
                            Text("\(selectedRepeat.rawValue) \(formattedTime)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(isEditing ? "リマインダーを編集" : "新規リマインダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveReminder() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    private func saveReminder() {
        if let existing = reminder {
            // 編集
            existing.title = title
            existing.reminderTypeRaw = selectedType.rawValue
            existing.time = time
            existing.repeatIntervalRaw = selectedRepeat.rawValue
            existing.notes = notes
            existing.isEnabled = isEnabled

            if isEnabled {
                NotificationManager.shared.scheduleNotification(for: existing)
            } else {
                NotificationManager.shared.removeNotification(for: existing)
            }
        } else {
            // 新規
            let newReminder = HealthReminder(
                title: title,
                reminderType: selectedType,
                time: time,
                repeatInterval: selectedRepeat,
                isEnabled: isEnabled,
                notes: notes
            )
            modelContext.insert(newReminder)
            NotificationManager.shared.scheduleNotification(for: newReminder)
        }
        dismiss()
    }
}

#Preview {
    AddReminderView()
        .modelContainer(for: [HealthRecord.self, HealthReminder.self], inMemory: true)
}
