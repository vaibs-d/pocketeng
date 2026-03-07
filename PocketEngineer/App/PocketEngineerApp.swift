import SwiftUI
import SwiftData

@main
struct PocketEngineerApp: App {
    let modelContainer: ModelContainer

    init() {
        NotificationService.requestPermission()

        let schema = Schema([
            ServerConfig.self,
            Session.self,
            ChatMessage.self,
            ToolActivity.self
        ])
        let config = ModelConfiguration(
            "PocketEngineer",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
