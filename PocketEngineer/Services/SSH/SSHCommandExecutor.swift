import Foundation

actor LineBufferedStream {
    private var buffer = ""
    private let handler: @Sendable (String) -> Void

    init(handler: @escaping @Sendable (String) -> Void) {
        self.handler = handler
    }

    func append(_ text: String) {
        buffer += text
        while let newlineIndex = buffer.firstIndex(of: "\n") {
            let line = String(buffer[buffer.startIndex..<newlineIndex])
            buffer = String(buffer[buffer.index(after: newlineIndex)...])
            if !line.isEmpty {
                handler(line)
            }
        }
    }

    func flush() {
        let remaining = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty {
            handler(remaining)
        }
        buffer = ""
    }
}

struct SSHCommandExecutor: Sendable {
    let sshService: SSHService

    func streamCommand(
        _ command: String,
        onLine: @escaping @Sendable (String) -> Void
    ) async throws {
        let lineStream = LineBufferedStream(handler: onLine)

        try await sshService.executeStreaming(command: command) { chunk, isStderr in
            if !isStderr {
                Task {
                    await lineStream.append(chunk)
                }
            }
        }

        await lineStream.flush()
    }
}
