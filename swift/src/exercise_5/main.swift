import SwiftUI
import SwiftData

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TaskItem.self)
    }
}


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    @State private var showAddSheet = false
    @State private var filter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "すべて"
        case active = "未完了"
        case completed = "完了済み"
    }
    
    var filteredTasks: [TaskItem] {
        switch filter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("フィルタ", selection: $filter) {
                    ForEach(TaskFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: EditTaskView(task: task)) {
                            TaskRowView(task: task)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(.plain)
            }
            .navigationTitle("タスク管理")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTaskView()
            }
            .overlay {
                if filteredTasks.isEmpty {
                    ContentUnavailableView {
                        Label("タスクがありません", systemImage: "checklist")
                    } description: {
                        Text("＋ボタンから新しいタスクを追加してください")
                    }
                }
            }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTasks[index])
        }
        try? modelContext.save()
    }
}