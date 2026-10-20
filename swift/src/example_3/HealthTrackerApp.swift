import SwiftUI
import SwiftData

@main
struct HealthTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: HealthRecord.self)
    }
}
