import SwiftUI

struct TaskRowView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                task.isCompleted.toggle()
                try? modelContext.save()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Label(task.dueDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(dateColor)
                    
                    Text(task.priority.title)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var dateColor: Color {
        if task.isCompleted { return .gray }
        return task.dueDate < Date() ? .red : .secondary
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var memo = ""
    @State private var dueDate = Date()
    @State private var priority: TaskItem.Priority = .medium
    
    var body: some View {
        NavigationStack {
            Form {
                Section("タスク名") {
                    TextField("例: レポートを提出", text: $title)
                }
                
                Section("詳細") {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                }
                
                Section("期限") {
                    DatePicker("日時", selection: $dueDate)
                }
                
                Section("優先度") {
                    Picker("優先度", selection: $priority) {
                        ForEach(TaskItem.Priority.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("新規タスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        let newTask = TaskItem(
            title: title,
            memo: memo,
            dueDate: dueDate,
            priority: priority
        )
        modelContext.insert(newTask)
        try? modelContext.save()
        dismiss()
    }
}