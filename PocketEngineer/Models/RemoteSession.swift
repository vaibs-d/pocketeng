import Foundation

struct RemoteSession: Identifiable {
    let id: String  // session UUID
    let firstMessage: String
    let lastTimestamp: Date
    let projectPath: String

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastTimestamp, relativeTo: Date())
    }

    var displayTitle: String {
        // Clean up the first message — strip leading "-\n" from Claude's format
        let cleaned = firstMessage
            .replacingOccurrences(of: "-\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count > 80 {
            return String(cleaned.prefix(80)) + "..."
        }
        return cleaned.isEmpty ? "Untitled session" : cleaned
    }
}
