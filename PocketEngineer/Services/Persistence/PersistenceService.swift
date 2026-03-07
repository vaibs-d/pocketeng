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

    func fetchAllServerConfigs() -> [ServerConfig] {
        let descriptor = FetchDescriptor<ServerConfig>(
            sortBy: [SortDescriptor(\.lastConnectedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSessions() -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSessions(for serverConfig: ServerConfig?) -> [Session] {
        let all = fetchSessions()
        guard let config = serverConfig else { return all }
        return all.filter { $0.serverConfig?.id == config.id }
    }

    func save() {
        try? modelContext.save()
    }
}
