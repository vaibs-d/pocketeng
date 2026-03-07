import Foundation

actor ClaudeSessionManager {
    private var sessions: [UUID: String] = [:] // localSessionId -> remoteSessionId

    func setRemoteId(_ remoteId: String, for localId: UUID) {
        sessions[localId] = remoteId
    }

    func remoteId(for localId: UUID) -> String? {
        sessions[localId]
    }

    func removeSession(_ localId: UUID) {
        sessions.removeValue(forKey: localId)
    }

    func clear() {
        sessions.removeAll()
    }
}
