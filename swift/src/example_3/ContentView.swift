import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthRecord.date, order: .reverse) private var records: [HealthRecord]

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Section {
                        Text("記録がありません")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    }
                } else {
                    Section("最近の記録") {
                        ForEach(records) { record in
                            NavigationLink(destination: RecordDetailView(record: record)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.formattedDate)
                                        .font(.headline)
                                    Text(record.summaryText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if !record.memo.isEmpty {
                                        Text(record.memo)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
            .navigationTitle("体調管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRecordView()
            }
        }
    }

    private func deleteRecords(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HealthRecord.self, inMemory: true)
}
