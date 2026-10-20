import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddSession = false
    @State private var sessionNote = ""
    @State private var sessionDuration = "30"

    var sortedSessions: [StudySession] {
        (subject.sessions ?? []).sorted { $0.startTime > $1.startTime }
    }

    var body: some View {
        List {
            Section(header: Text("進捗概要")) {
                VStack(spacing: 16) {
                    ProgressRing(ratio: subject.progressRatio, color: Color(hex: subject.colorHex))
                        .frame(width: 120, height: 120)

                    VStack(spacing: 4) {
                        Text("\(subject.totalStudyMinutes) / \(subject.goalMinutes) 分")
                            .font(.title2.bold())
                        Text("目標達成率 \(Int(subject.progressRatio * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section(header: Text("学習履歴")) {
                if sortedSessions.isEmpty {
                    Text("まだ学習記録がありません")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(sortedSessions) { session in
                        SessionRowView(session: session)
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
        }
        .navigationTitle(subject.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSession = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            NavigationStack {
                Form {
                    Section(header: Text("学習時間（分）")) {
                        TextField("30", text: $sessionDuration)
                            .keyboardType(.numberPad)
                    }
                    Section(header: Text("メモ")) {
                        TextEditor(text: $sessionNote)
                            .frame(minHeight: 80)
                    }
                }
                .navigationTitle("学習を記録")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            showingAddSession = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            addSession()
                        }
                    }
                }
            }
        }
    }

    private func addSession() {
        guard let duration = Int(sessionDuration), duration > 0 else { return }
        let endTime = Date()
        let startTime = Calendar.current.date(byAdding: .minute, value: -duration, to: endTime) ?? endTime

        let session = StudySession(
            startTime: startTime,
            endTime: endTime,
            durationMinutes: duration,
            note: sessionNote,
            subject: subject
        )
        modelContext.insert(session)

        sessionNote = ""
        sessionDuration = "30"
        showingAddSession = false
    }

    private func deleteSessions(offsets: IndexSet) {
        let sessions = sortedSessions
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

struct SessionRowView: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startTime, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(session.durationMinutes) 分")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !session.note.isEmpty {
                Text(session.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
