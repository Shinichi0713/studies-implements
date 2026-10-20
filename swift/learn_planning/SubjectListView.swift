import SwiftUI
import SwiftData

struct SubjectListView: View {
    @Query(sort: \Subject.createdAt) var subjects: [Subject]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddSubject = false
    @State private var newSubjectName = ""
    @State private var newSubjectGoal = "60"
    @State private var selectedColor = "#FF6B6B"

    let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEEAD", "#D4A5A5", "#9B59B6", "#3498DB"
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects) { subject in
                    NavigationLink(destination: SubjectDetailView(subject: subject)) {
                        SubjectRowView(subject: subject)
                    }
                }
                .onDelete(perform: deleteSubjects)
            }
            .navigationTitle("学習科目")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                NavigationStack {
                    Form {
                        Section(header: Text("科目名")) {
                            TextField("例: 数学", text: $newSubjectName)
                        }

                        Section(header: Text("目標時間（分）")) {
                            TextField("60", text: $newSubjectGoal)
                                .keyboardType(.numberPad)
                        }

                        Section(header: Text("色")) {
                            LazyVGrid(columns: Array(repeating: GridItem(), count: 4), spacing: 12) {
                                ForEach(colorOptions, id: \self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                        }
                    }
                    .navigationTitle("新規科目")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                showingAddSubject = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") {
                                addSubject()
                            }
                            .disabled(newSubjectName.isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func addSubject() {
        guard !newSubjectName.isEmpty, let goal = Int(newSubjectGoal) else { return }
        let subject = Subject(name: newSubjectName, colorHex: selectedColor, goalMinutes: goal)
        modelContext.insert(subject)
        showingAddSubject = false
        newSubjectName = ""
        newSubjectGoal = "60"
    }

    private func deleteSubjects(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(subjects[index])
        }
    }
}

struct SubjectRowView: View {
    let subject: Subject

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: subject.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(subject.name)
                    .font(.headline)
                Text("\(subject.totalStudyMinutes) / \(subject.goalMinutes) 分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ProgressRing(ratio: subject.progressRatio, color: Color(hex: subject.colorHex))
                .frame(width: 40, height: 40)
        }
        .padding(.vertical, 4)
    }
}

struct ProgressRing: View {
    let ratio: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
