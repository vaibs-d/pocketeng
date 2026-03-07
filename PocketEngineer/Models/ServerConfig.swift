import SwiftData
import Foundation

@Model
final class ServerConfig {
    var id: UUID
    var host: String
    var port: Int
    var username: String
    var privateKeyReference: String
    var label: String
    var workingDirectory: String
    var createdAt: Date
    var lastConnectedAt: Date?

    init(
        host: String,
        port: Int = 22,
        username: String,
        privateKeyReference: String,
        label: String = "",
        workingDirectory: String = "~"
    ) {
        self.id = UUID()
        self.host = host
        self.port = port
        self.username = username
        self.privateKeyReference = privateKeyReference
        self.label = label.isEmpty ? host : label
        self.workingDirectory = workingDirectory
        self.createdAt = Date()
    }
}
