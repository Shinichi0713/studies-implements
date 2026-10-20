import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: HealthRecord

    @State private var isEditing = false
    @State private var editedDate: Date
    @State private var editedBodyTemperatureText: String
    @State private var editedWeightText: String
    @State private var editedSystolicText: String
    @State private var editedDiastolicText: String
    @State private var editedHeartRateText: String
    @State private var editedMemo: String

    init(record: HealthRecord) {
        self.record = record
        _editedDate = State(initialValue: record.date)
        _editedBodyTemperatureText = State(initialValue: record.bodyTemperature != nil ? String(format: "%.1f", record.bodyTemperature!) : "")
        _editedWeightText = State(initialValue: record.weight != nil ? String(format: "%.1f", record.weight!) : "")
        _editedSystolicText = State(initialValue: record.systolicBloodPressure != nil ? String(record.systolicBloodPressure!) : "")
        _editedDiastolicText = State(initialValue: record.diastolicBloodPressure != nil ? String(record.diastolicBloodPressure!) : "")
        _editedHeartRateText = State(initialValue: record.heartRate != nil ? String(record.heartRate!) : "")
        _editedMemo = State(initialValue: record.memo)
    }

    var body: some View {
        Form {
            Section("日時") {
                if isEditing {
                    DatePicker("記録日時", selection: $editedDate)
                } else {
                    Text(record.formattedDate)
                }
            }

            Section("基本情報") {
                if isEditing {
                    HStack {
                        Text("体温")
                        Spacer()
                        TextField("36.5", text: $editedBodyTemperatureText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("°C")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("60.0", text: $editedWeightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    LabeledContent("体温", value: record.bodyTemperature != nil ? String(format: "%.1f °C", record.bodyTemperature!) : "未入力")
                    LabeledContent("体重", value: record.weight != nil ? String(format: "%.1f kg", record.weight!) : "未入力")
                }
            }

            Section("血圧") {
                if isEditing {
                    HStack {
                        Text("最高血圧")
                        Spacer()
                        TextField("120", text: $editedSystolicText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmHg")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("最低血圧")
                        Spacer()
                        TextField("80", text: $editedDiastolicText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmHg")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if let sys = record.systolicBloodPressure, let dia = record.diastolicBloodPressure {
                        LabeledContent("血圧", value: "\(sys) / \(dia) mmHg")
                    } else {
                        LabeledContent("血圧", value: "未入力")
                    }
                }
            }

            Section("その他") {
                if isEditing {
                    HStack {
                        Text("脈拍")
                        Spacer()
                        TextField("70", text: $editedHeartRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("bpm")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    LabeledContent("脈拍", value: record.heartRate != nil ? "\(record.heartRate!) bpm" : "未力")
                }
            }

            Section("メモ") {
                if isEditing {
                    TextEditor(text: $editedMemo)
                        .frame(minHeight: 80)
                } else {
                    Text(record.memo.isEmpty ? "なし" : record.memo)
                        .foregroundStyle(record.memo.isEmpty ? .secondary : .primary)
                }
            }

            if !isEditing {
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(record)
                        dismiss()
                    } label: {
                        Label("この記録を削除", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle("記録詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    if isEditing {
                        updateRecord()
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    private func updateRecord() {
        record.date = editedDate
        record.bodyTemperature = Double(editedBodyTemperatureText)
        record.weight = Double(editedWeightText)
        record.systolicBloodPressure = Int(editedSystolicText)
        record.diastolicBloodPressure = Int(editedDiastolicText)
        record.heartRate = Int(editedHeartRateText)
        record.memo = editedMemo
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: HealthRecord.self, configurations: config)
    let record = HealthRecord(
        date: Date(),
        bodyTemperature: 36.5,
        weight: 62.5,
        systolicBloodPressure: 118,
        diastolicBloodPressure: 76,
        heartRate: 72,
        memo: "今日は調子が良い"
    )
    return NavigationStack {
        RecordDetailView(record: record)
            .modelContainer(container)
    }
}
