import Foundation
import SwiftData
import Observation

@Observable
final class SessionListViewModel {
    var sessions: [Session] = []
    var showNewSessionSheet: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSessions()
    }

    func fetchSessions() {
        let persistence = PersistenceService(modelContext: modelContext)
        sessions = persistence.fetchSessions()
    }

    func fetchSessions(for serverConfig: ServerConfig?) {
        let persistence = PersistenceService(modelContext: modelContext)
        sessions = persistence.fetchSessions(for: serverConfig)
    }

    func createSession(title: String, serverConfig: ServerConfig?) -> Session {
        let session = Session(title: title, serverConfig: serverConfig)
        modelContext.insert(session)
        try? modelContext.save()
        sessions.insert(session, at: 0)
        return session
    }

    func deleteSession(_ session: Session) {
        modelContext.delete(session)
        try? modelContext.save()
        sessions.removeAll { $0.id == session.id }
    }

    func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            modelContext.delete(session)
        }
        try? modelContext.save()
        sessions.remove(atOffsets: offsets)
    }
}
