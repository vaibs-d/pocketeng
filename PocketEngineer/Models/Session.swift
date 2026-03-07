import SwiftData
import Foundation

enum SessionStatus: String, Codable {
    case active
    case idle
    case completed
    case error
}

@Model
final class Session {
    var id: UUID
    var title: String
    var remoteSessionId: String?
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date

    var projectContext: String?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]

    var serverConfig: ServerConfig?

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .idle }
        set { statusRaw = newValue.rawValue }
    }

    init(title: String, serverConfig: ServerConfig? = nil) {
        self.id = UUID()
        self.title = title
        self.statusRaw = SessionStatus.idle.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
        self.serverConfig = serverConfig
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
}
