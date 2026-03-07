import Foundation
import SwiftData

struct PersistenceService {
    let modelContext: ModelContext

    func fetchServerConfig() -> ServerConfig? {
        let descriptor = FetchDescriptor<ServerConfig>(
            sortBy: [SortDescriptor(\.lastConnectedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    func fetchSessions() -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func save() {
        try? modelContext.save()
    }
}
