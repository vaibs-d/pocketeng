import SwiftData
import Foundation

enum ToolType: String, Codable {
    case bash
    case read
    case edit
    case write
    case glob
    case grep
    case task
    case unknown
}

@Model
final class ToolActivity {
    var id: UUID
    var toolName: String
    var toolTypeRaw: String
    var input: String
    var output: String?
    var timestamp: Date
    var durationMs: Int?

    var message: ChatMessage?

    var toolType: ToolType {
        get { ToolType(rawValue: toolTypeRaw) ?? .unknown }
        set { toolTypeRaw = newValue.rawValue }
    }

    init(toolName: String, input: String) {
        self.id = UUID()
        self.toolName = toolName
        self.toolTypeRaw = (ToolType(rawValue: toolName.lowercased()) ?? .unknown).rawValue
        self.input = input
        self.timestamp = Date()
    }
}
