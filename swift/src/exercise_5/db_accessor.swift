import SwiftData
import Foundation

// MARK: - TaskRepository
@MainActor
final class TaskRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: Insert
    func addTask(_ task: TaskItem) throws {
        context.insert(task)
        try context.save()
    }
    
    // MARK: Update
    func update() throws {
        try context.save()
    }
    
    func toggleComplete(_ task: TaskItem) throws {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        try context.save()
    }
    
    // MARK: Delete
    func delete(_ task: TaskItem) throws {
        context.delete(task)
        try context.save()
    }
    
    func deleteTasks(_ tasks: [TaskItem]) throws {
        tasks.forEach { context.delete($0) }
        try context.save()
    }
    
    // MARK: Fetch
    func fetchTasks(
        filter: TaskFilter = .all,
        sort: SortDescriptor<TaskItem> = SortDescriptor(\.dueDate),
        searchText: String = "",
        category: Category? = nil
    ) throws -> [TaskItem] {
        var predicates: [Predicate<TaskItem>] = []
        
        // 完了状態フィルタ
        switch filter {
        case .active:
            predicates.append(#Predicate { $0.isCompleted == false })
        case .completed:
            predicates.append(#Predicate { $0.isCompleted == true })
        case .all:
            break
        }
        
        // 検索テキスト
        if !searchText.isEmpty {
            let query = searchText
            predicates.append(#Predicate { $0.title.localizedStandardContains(query) })
        }
        
        // カテゴリフィルタ
        if let category = category {
            let cid = category.persistentModelID
            predicates.append(#Predicate { item in
                item.category?.persistentModelID == cid
            })
        }
        
        // 複合Predicate
        let finalPredicate: Predicate<TaskItem>
        if predicates.isEmpty {
            finalPredicate = #Predicate { _ in true }
        } else if predicates.count == 1 {
            finalPredicate = predicates[0]
        } else {
            // 複数条件のAND結合（SwiftDataのPredicate合成）
            finalPredicate = #Predicate { item in
                predicates.allSatisfy { $0.evaluate(item) }
            }
        }
        
        var descriptor = FetchDescriptor<TaskItem>(
            predicate: finalPredicate,
            sortBy: [sort]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }
    
    // MARK: Statistics
    func statistics() throws -> TaskStatistics {
        let all = try context.fetch(FetchDescriptor<TaskItem>())
        let total = all.count
        let completed = all.filter(\.isCompleted).count
        let active = total - completed
        let completionRate = total == 0 ? 0.0 : Double(completed) / Double(total)
        
        // 期限切れカウント
        let overdue = all.filter { !$0.isCompleted && $0.dueDate < Date() }.count
        
        return TaskStatistics(
            total: total,
            active: active,
            completed: completed,
            overdue: overdue,
            completionRate: completionRate
        )
    }
}

// MARK: - Supporting Types
enum TaskFilter: String, CaseIterable {
    case all = "すべて"
    case active = "未完了"
    case completed = "完了済み"
}

struct TaskStatistics {
    let total: Int
    let active: Int
    let completed: Int
    let overdue: Int
    let completionRate: Double
}

import SwiftUI
import SwiftData

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var categories: [Category] = []
    @Published var statistics: TaskStatistics = .init(total: 0, active: 0, completed: 0, overdue: 0, completionRate: 0)
    @Published var filter: TaskFilter = .all
    @Published var searchText: String = ""
    @Published var selectedCategory: Category? = nil
    
    private let repository: TaskRepository
    
    init(context: ModelContext) {
        self.repository = TaskRepository(context: context)
    }
    
    func load() {
        do {
            tasks = try repository.fetchTasks(
                filter: filter,
                searchText: searchText,
                category: selectedCategory
            )
            categories = try repository.fetchCategories()
            statistics = try repository.statistics()
        } catch {
            print("DB読み込みエラー: \(error)")
        }
    }
    
    func addTask(_ task: TaskItem) {
        do {
            try repository.addTask(task)
            load()
        } catch {
            print("追加エラー: \(error)")
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        do {
            try repository.delete(task)
            load()
        } catch {
            print("削除エラー: \(error)")
        }
    }
    
    func toggleComplete(_ task: TaskItem) {
        do {
            try repository.toggleComplete(task)
            load()
        } catch {
            print("更新エラー: \(error)")
        }
    }
    
    func addCategory(name: String, color: String) {
        // ViewModel内で直接contextにアクセスする必要があるため、
        // 実際にはModelContextを渡してCategoryを作成するか、
        // RepositoryにaddCategoryを追加します
    }
}