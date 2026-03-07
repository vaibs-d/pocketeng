import Foundation

actor ClaudeService {
    private let sshService: SSHService
    private let sessionManager = ClaudeSessionManager()
    private let parser = ClaudeOutputParser()
    private var currentTask: Task<Void, Error>?

    init(sshService: SSHService) {
        self.sshService = sshService
    }

    func sendMessage(
        message: String,
        localSessionId: UUID,
        remoteSessionId: String?,
        workingDirectory: String,
        onEvent: @escaping @Sendable (ClaudeEvent) -> Void
    ) async throws {
        // Base64 encode user input to avoid shell injection
        let base64Message = Data(message.utf8).base64EncodedString()

        var command = "cd \(shellEscape(workingDirectory)) && "
        command += "echo '\(base64Message)' | base64 -d | "
        command += "claude -p - "
        command += "--output-format stream-json "
        command += "--verbose "
        command += "--dangerously-skip-permissions"

        if let sessionId = remoteSessionId {
            command += " --resume '\(shellEscape(sessionId))'"
        }

        let executor = SSHCommandExecutor(sshService: sshService)
        let capturedParser = parser

        currentTask = Task {
            try await executor.streamCommand(command) { line in
                if let event = capturedParser.parseLine(line) {
                    // Track remote session ID
                    if case .initialized(let remoteId) = event {
                        Task {
                            await self.sessionManager.setRemoteId(remoteId, for: localSessionId)
                        }
                    }
                    onEvent(event)
                }
            }
        }

        try await currentTask?.value
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    func remoteSessionId(for localId: UUID) async -> String? {
        await sessionManager.remoteId(for: localId)
    }

    func verifyClaudeInstalled() async throws -> Bool {
        do {
            let output = try await sshService.executeCommand("which claude 2>/dev/null && claude --version 2>/dev/null || echo 'NOT_FOUND'")
            return !output.contains("NOT_FOUND")
        } catch {
            return false
        }
    }

    func runCommand(_ command: String) async throws -> String {
        try await sshService.executeCommand(command)
    }

    private func shellEscape(_ string: String) -> String {
        string.replacingOccurrences(of: "'", with: "'\\''")
    }
}
