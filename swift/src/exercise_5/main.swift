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

import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section("タスク名") {
                TextField("タスク名", text: $task.title)
            }
            
            Section("詳細") {
                TextEditor(text: $task.memo)
                    .frame(minHeight: 80)
            }
            
            Section("期限") {
                DatePicker("日時", selection: $task.dueDate)
            }
            
            Section("優先度") {
                Picker("優先度", selection: $task.priority) {
                    ForEach(TaskItem.Priority.allCases) { p in
                        Text(p.title).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Toggle("完了済み", isOn: $task.isCompleted)
            }
            
            Section {
                Button(role: .destructive) {
                    modelContext.delete(task)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Text("タスクを削除")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("タスク詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}