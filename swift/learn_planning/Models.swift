import Foundation
import SwiftData

@Model
class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    var goalMinutes: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StudySession.subject)
    var sessions: [StudySession]?

    init(name: String, colorHex: String, goalMinutes: Int) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.goalMinutes = goalMinutes
        self.createdAt = Date()
    }

    var totalStudyMinutes: Int {
        sessions?.reduce(0) { $0 + $1.durationMinutes } ?? 0
    }

    var progressRatio: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(totalStudyMinutes) / Double(goalMinutes), 1.0)
    }
}

@Model
class StudySession {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var durationMinutes: Int
    var note: String

    var subject: Subject?

    init(startTime: Date, endTime: Date, durationMinutes: Int, note: String = "", subject: Subject? = nil) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.note = note
        self.subject = subject
    }
}
