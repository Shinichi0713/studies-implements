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

import SwiftData
import Foundation

// MARK: - Category
@Model
final class Category {
    var name: String
    var colorHex: String // 例: "#FF5733"
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.category)
    var tasks: [TaskItem]?
    
    init(name: String, colorHex: String = "#666666") {
        self.name = name
        self.colorHex = colorHex
    }
}

// MARK: - TaskItem
@Model
final class TaskItem {
    var title: String
    var memo: String
    var dueDate: Date
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    
    @Relationship(inverse: \Category.tasks)
    var category: Category?
    
    enum Priority: Int, Codable, CaseIterable, Identifiable {
        case low = 0, medium = 1, high = 2
        var id: Int { rawValue }
        var title: String {
            switch self { case .low: "低"; case .medium: "中"; case .high: "高" }
        }
    }
    
    init(
        title: String,
        memo: String = "",
        dueDate: Date = Date(),
        priority: Priority = .medium,
        category: Category? = nil
    ) {
        self.title = title
        self.memo = memo
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
        self.category = category
    }
}