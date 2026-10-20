import SwiftUI
import SwiftData

struct StudyTimerView: View {
    @Query(sort: \Subject.createdAt) var subjects: [Subject]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSubject: Subject? = nil
    @State private var isRunning = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer? = nil
    @State private var sessionNote = ""
    @State private var showingSaveSheet = false

    var elapsedMinutes: Int {
        elapsedSeconds / 60
    }

    var displayTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // 科目選択
                Picker("科目", selection: $selectedSubject) {
                    Text("科目を選択").tag(nil as Subject?)
                    ForEach(subjects) { subject in
                        Text(subject.name).tag(subject as Subject?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .disabled(isRunning)

                // タイマー表示
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 260, height: 260)

                    if isRunning, let subject = selectedSubject {
                        Circle()
                            .trim(from: 0, to: min(CGFloat(elapsedSeconds) / 3600.0, 1.0))
                            .stroke(Color(hex: subject.colorHex), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 260, height: 260)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: elapsedSeconds)
                    }

                    VStack(spacing: 8) {
                        Text(displayTime)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                        if let subject = selectedSubject {
                            Text(subject.name)
                                .font(.title3)
                                .foregroundStyle(Color(hex: subject.colorHex))
                        } else {
                            Text("科目未選択")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 300)

                // コントロールボタン
                HStack(spacing: 24) {
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(isRunning ? .orange : (selectedSubject == nil ? .gray : .green))
                    }
                    .disabled(selectedSubject == nil && !isRunning)

                    Button(action: stopAndSave) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.red)
                    }
                    .disabled(!isRunning && elapsedSeconds == 0)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("学習タイマー")
            .sheet(isPresented: $showingSaveSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("学習時間")) {
                            Text("\(elapsedMinutes) 分")
                                .font(.headline)
                        }
                        Section(header: Text("メモ")) {
                            TextEditor(text: $sessionNote)
                                .frame(minHeight: 100)
                        }
                    }
                    .navigationTitle("学習を記録")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("破棄") {
                                resetTimer()
                                showingSaveSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") {
                                saveSession()
                                showingSaveSheet = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
        } else {
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedSeconds += 1
            }
        }
    }

    private func stopAndSave() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        if elapsedSeconds >= 60 {
            showingSaveSheet = true
        } else {
            // 1分未満は保存せずリセット
            resetTimer()
        }
    }

    private func saveSession() {
        guard let subject = selectedSubject else { return }
        let endTime = Date()
        let startTime = Calendar.current.date(byAdding: .second, value: -elapsedSeconds, to: endTime) ?? endTime

        let session = StudySession(
            startTime: startTime,
            endTime: endTime,
            durationMinutes: elapsedMinutes,
            note: sessionNote,
            subject: subject
        )
        modelContext.insert(session)
        resetTimer()
    }

    private func resetTimer() {
        elapsedSeconds = 0
        sessionNote = ""
    }
}
