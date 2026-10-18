import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            SubjectListView()
                .tabItem {
                    Label("科目", systemImage: "book.closed")
                }

            StudyTimerView()
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }

            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subject.self, StudySession.self], inMemory: true)
}
