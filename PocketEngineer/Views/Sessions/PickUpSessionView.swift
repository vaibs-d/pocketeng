import SwiftUI

struct PickUpSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var remoteSessions: [RemoteSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let sshService: SSHService
    let onPickUp: (RemoteSession) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.brandPurple)
                        Text("Finding sessions on EC2...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await discoverSessions() }
                        }
                        .foregroundColor(.brandPurple)
                    }
                    .padding()
                } else if remoteSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("No sessions found on EC2")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(remoteSessions) { session in
                            Button {
                                onPickUp(session)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(session.displayTitle)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                        Text(session.timeAgo)
                                            .font(.caption)
                                        Spacer()
                                        Text(session.id.prefix(8))
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pick Up Session")
            .iOSNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await discoverSessions()
        }
    }

    private func discoverSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            // Find all session JSONL files on EC2 and extract metadata
            let script = """
            for dir in ~/.claude/projects/*/; do
              project=$(basename "$dir")
              for f in "$dir"*.jsonl; do
                [ -f "$f" ] || continue
                sid=$(basename "$f" .jsonl)
                first=$(head -1 "$f" 2>/dev/null)
                last=$(tail -1 "$f" 2>/dev/null)
                echo "SESSION|$sid|$project|$first|$last"
              done
            done
            """

            let output = try await sshService.executeCommand(script)
            let lines = output.components(separatedBy: "\n").filter { $0.hasPrefix("SESSION|") }

            var sessions: [RemoteSession] = []
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            for line in lines {
                let parts = line.components(separatedBy: "|")
                guard parts.count >= 5 else { continue }

                let sessionId = parts[1]
                let projectPath = parts[2]
                let firstJson = parts[3]
                let lastJson = parts.dropFirst(4).joined(separator: "|")

                // Skip subagent sessions
                if sessionId.hasPrefix("agent-") { continue }

                // Extract first message content
                let firstMessage = extractContent(from: firstJson)

                // Extract last timestamp
                let lastTimestamp = extractTimestamp(from: lastJson, formatter: isoFormatter)

                sessions.append(RemoteSession(
                    id: sessionId,
                    firstMessage: firstMessage,
                    lastTimestamp: lastTimestamp ?? Date.distantPast,
                    projectPath: projectPath
                ))
            }

            // Sort by most recent
            remoteSessions = sessions.sorted { $0.lastTimestamp > $1.lastTimestamp }
            isLoading = false

        } catch {
            errorMessage = "Couldn't connect to EC2: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func extractContent(from json: String) -> String {
        // Quick parse: find "content":"..." in the JSON
        guard let range = json.range(of: "\"content\":\"") else { return "" }
        let start = range.upperBound
        var end = start
        var escaped = false
        for char in json[start...] {
            if escaped {
                escaped = false
                end = json.index(after: end)
                continue
            }
            if char == "\\" { escaped = true; end = json.index(after: end); continue }
            if char == "\"" { break }
            end = json.index(after: end)
        }
        return String(json[start..<end])
            .replacingOccurrences(of: "\\n", with: " ")
            .replacingOccurrences(of: "-\\n", with: "")
    }

    private func extractTimestamp(from json: String, formatter: ISO8601DateFormatter) -> Date? {
        guard let range = json.range(of: "\"timestamp\":\"") else { return nil }
        let start = range.upperBound
        guard let end = json[start...].firstIndex(of: "\"") else { return nil }
        let ts = String(json[start..<end])
        return formatter.date(from: ts)
    }
}
