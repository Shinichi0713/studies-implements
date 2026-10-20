import SwiftUI
import SwiftData

@main
struct HealthTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// CloudKit同期対応のモデルコンテナ
var sharedModelContainer: ModelContainer = {
    let schema = Schema([HealthRecord.self])
    // CloudKitを使ったiCloud同期を有効化
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .automatic
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
