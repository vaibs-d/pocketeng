import Foundation

enum SSHConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

enum SSHError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case authenticationFailed
    case channelOpenFailed
    case timeout
    case keyParsingFailed(String)
    case commandFailed(Int)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .connectionFailed(let detail):
            return "Connection failed: \(detail)"
        case .authenticationFailed:
            return "Authentication failed. Check your SSH key and username."
        case .channelOpenFailed:
            return "Failed to open SSH channel"
        case .timeout:
            return "Connection timed out"
        case .keyParsingFailed(let detail):
            return "Invalid SSH key: \(detail)"
        case .commandFailed(let code):
            return "Command exited with code \(code)"
        }
    }
}

enum ClaudeError: LocalizedError {
    case notInstalled
    case sessionExpired
    case commandFailed(exitCode: Int, stderr: String)
    case parsingFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Claude CLI not found on remote server. Make sure claude is installed."
        case .sessionExpired:
            return "Session expired. Start a new conversation."
        case .commandFailed(let code, let stderr):
            return "Claude exited with code \(code): \(stderr)"
        case .parsingFailed(let detail):
            return "Failed to parse output: \(detail)"
        case .cancelled:
            return "Task was cancelled"
        }
    }
}

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidKeyFormat
    case notFound

    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store key in Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve key from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete key from Keychain (status: \(status))"
        case .invalidKeyFormat:
            return "Invalid SSH key format. Expected PEM or OpenSSH format."
        case .notFound:
            return "SSH key not found in Keychain"
        }
    }
}
