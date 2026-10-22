import SwiftData
import Foundation

@Model
final class TaskItem {
    var title: String
    var memo: String
    var dueDate: Date
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    
    enum Priority: Int, Codable, CaseIterable, Identifiable {
        case low = 0
        case medium = 1
        case high = 2
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
    
    init(
        title: String,
        memo: String = "",
        dueDate: Date = Date(),
        priority: Priority = .medium,
        isCompleted: Bool = false
    ) {
        self.title = title
        self.memo = memo
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}