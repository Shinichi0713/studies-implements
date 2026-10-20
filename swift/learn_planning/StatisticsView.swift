import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Subject.createdAt) var subjects: [Subject]
    @Query(sort: \StudySession.endTime, order: .reverse) var allSessions: [StudySession]

    var totalStudyMinutes: Int {
        allSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var todayStudyMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allSessions
            .filter { $0.endTime >= today }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var weekStudyMinutes: Int {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return allSessions
            .filter { $0.endTime >= weekAgo }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("概要")) {
                    HStack(spacing: 16) {
                        StatCard(title: "今日", value: "\(todayStudyMinutes)分", color: .blue)
                        StatCard(title: "7日間", value: "\(weekStudyMinutes)分", color: .green)
                        StatCard(title: "合計", value: "\(totalStudyMinutes)分", color: .orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section(header: Text("科目別 学習時間")) {
                    if subjects.isEmpty {
                        Text("科目が登録されていません")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(subjects) { subject in
                            HStack {
                                Circle()
                                    .fill(Color(hex: subject.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(subject.name)
                                Spacer()
                                Text("\(subject.totalStudyMinutes) 分")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(header: Text("最近の学習記録")) {
                    let recentSessions = Array(allSessions.prefix(10))
                    if recentSessions.isEmpty {
                        Text("まだ学習記録がありません")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(recentSessions) { session in
                            if let subject = session.subject {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: subject.colorHex))
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(subject.name)
                                            .font(.subheadline.bold())
                                        Text(session.endTime, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(session.durationMinutes)分")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("統計")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
