import SwiftUI
import SwiftData

struct AddRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var bodyTemperatureText = ""
    @State private var weightText = ""
    @State private var systolicText = ""
    @State private var diastolicText = ""
    @State private var heartRateText = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("日時") {
                    DatePicker("記録日時", selection: $date)
                }

                Section("基本情報") {
                    HStack {
                        Text("体温")
                        Spacer()
                        TextField("36.5", text: $bodyTemperatureText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("°C")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("60.0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("血圧") {
                    HStack {
                        Text("最高血圧")
                        Spacer()
                        TextField("120", text: $systolicText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmHg")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("最低血圧")
                        Spacer()
                        TextField("80", text: $diastolicText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmHg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("その他") {
                    HStack {
                        Text("脈拍")
                        Spacer()
                        TextField("70", text: $heartRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("bpm")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("メモ") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("新規記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveRecord() }
                }
            }
        }
    }

    private func saveRecord() {
        let record = HealthRecord(
            date: date,
            bodyTemperature: Double(bodyTemperatureText),
            weight: Double(weightText),
            systolicBloodPressure: Int(systolicText),
            diastolicBloodPressure: Int(diastolicText),
            heartRate: Int(heartRateText),
            memo: memo
        )
        modelContext.insert(record)
        dismiss()
    }
}

#Preview {
    AddRecordView()
        .modelContainer(for: HealthRecord.self, inMemory: true)
}
