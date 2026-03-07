import SwiftData
import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageState: String, Codable {
    case complete
    case streaming
    case error
}

@Model
final class ChatMessage {
    var id: UUID
    var roleRaw: String
    var content: String
    var stateRaw: String
    var timestamp: Date

    var session: Session?

    @Relationship(deleteRule: .cascade, inverse: \ToolActivity.message)
    var toolActivities: [ToolActivity]

    var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .system }
        set { roleRaw = newValue.rawValue }
    }

    var state: MessageState {
        get { MessageState(rawValue: stateRaw) ?? .complete }
        set { stateRaw = newValue.rawValue }
    }

    init(role: MessageRole, content: String, state: MessageState = .complete) {
        self.id = UUID()
        self.roleRaw = role.rawValue
        self.content = content
        self.stateRaw = state.rawValue
        self.timestamp = Date()
        self.toolActivities = []
    }

    var sortedToolActivities: [ToolActivity] {
        toolActivities.sorted { $0.timestamp < $1.timestamp }
    }
}
