import SwiftUI
import SwiftData

@main
struct StudyManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Subject.self, StudySession.self])
    }
}
