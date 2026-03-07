import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var isStreaming: Bool = false
    var currentStreamingText: String = ""
    var currentToolActivities: [ToolActivity] = []
    var sessionStatus: SessionStatus = .idle
    var errorMessage: String?
    var inputText: String = ""
    var deployedURL: String?
    var isDeploying: Bool = false
    var showPreview: Bool = false

    private let claudeService: ClaudeService
    private let modelContext: ModelContext
    private(set) var session: Session

    init(session: Session, claudeService: ClaudeService, modelContext: ModelContext) {
        self.session = session
        self.claudeService = claudeService
        self.modelContext = modelContext
        self.messages = session.sortedMessages
        self.sessionStatus = session.status
    }

    /// Auto-send an initial prompt (used by templates)
    func autoSendInitialPrompt(_ prompt: String) async {
        inputText = prompt
        await sendMessage()
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        inputText = ""

        // Write CLAUDE.md if project context is set
        if let context = session.projectContext, !context.isEmpty {
            let workDir = session.serverConfig?.workingDirectory ?? "~/projects"
            let base64Context = Data(context.utf8).base64EncodedString()
            let writeCmd = "echo '\(base64Context)' | base64 -d > \(workDir)/CLAUDE.md"
            _ = try? await claudeService.runCommand(writeCmd)
        }

        // Create user message
        let userMessage = ChatMessage(role: .user, content: text)
        userMessage.session = session
        modelContext.insert(userMessage)
        messages.append(userMessage)

        // Create streaming assistant message placeholder
        let assistantMessage = ChatMessage(role: .assistant, content: "", state: .streaming)
        assistantMessage.session = session
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)

        isStreaming = true
        sessionStatus = .active
        session.status = .active
        currentStreamingText = ""
        currentToolActivities = []
        errorMessage = nil

        do {
            var remoteId = session.remoteSessionId
            if remoteId == nil {
                remoteId = await claudeService.remoteSessionId(for: session.id)
            }
            let workDir = session.serverConfig?.workingDirectory ?? "~"

            try await claudeService.sendMessage(
                message: text,
                localSessionId: session.id,
                remoteSessionId: remoteId,
                workingDirectory: workDir
            ) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleEvent(event, assistantMessage: assistantMessage)
                }
            }

            // Streaming finished successfully
            assistantMessage.state = .complete
            if !currentStreamingText.isEmpty {
                assistantMessage.content = currentStreamingText
            }
            isStreaming = false
            sessionStatus = .idle
            session.status = .idle
            session.updatedAt = Date()

            // Update remote session ID
            if let newRemoteId = await claudeService.remoteSessionId(for: session.id) {
                session.remoteSessionId = newRemoteId
            }

            try? modelContext.save()

            // Notify if backgrounded — include tool summary
            let toolCount = currentToolActivities.count
            let summary = toolCount > 0
                ? "\(session.title): done (\(toolCount) tool\(toolCount == 1 ? "" : "s") used)"
                : "\(session.title): done"
            NotificationService.notifyTaskComplete(sessionTitle: session.title, summary: summary)

        } catch is CancellationError {
            assistantMessage.state = .complete
            assistantMessage.content = currentStreamingText.isEmpty
                ? "Task cancelled."
                : currentStreamingText + "\n\n(Cancelled)"
            isStreaming = false
            sessionStatus = .idle
            session.status = .idle
            try? modelContext.save()

        } catch {
            assistantMessage.state = .error
            assistantMessage.content = currentStreamingText.isEmpty
                ? "Error: \(error.localizedDescription)"
                : currentStreamingText + "\n\nError: \(error.localizedDescription)"
            isStreaming = false
            sessionStatus = .error
            session.status = .error
            errorMessage = error.localizedDescription
            try? modelContext.save()
        }
    }

    func cancelTask() {
        Task {
            await claudeService.cancel()
        }
        isStreaming = false
        sessionStatus = .idle
    }

    func retryLastMessage() async {
        // Remove the last assistant message (error), re-send the last user message
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }

        // Remove error assistant message
        if let lastAssistant = messages.last, lastAssistant.role == .assistant && lastAssistant.state == .error {
            modelContext.delete(lastAssistant)
            messages.removeLast()
        }

        inputText = lastUserMessage.content
        await sendMessage()
    }

    /// Ask Claude to find and start a running app, returning the public URL
    func deploy() async {
        guard !isDeploying else { return }
        isDeploying = true
        deployedURL = nil

        do {
            let host = session.serverConfig?.host ?? DefaultEC2Config.host
            let workDir = session.serverConfig?.workingDirectory ?? "~/projects"

            // Ask Claude to find a runnable app and start it
            let findCmd = """
            cd \(workDir) && \
            PORT=8080 && \
            (lsof -ti:$PORT | xargs -r kill -9 2>/dev/null || true) && \
            sleep 1 && \
            if [ -f "requirements.txt" ] || [ -f "app.py" ] || [ -f "main.py" ]; then \
              FILE=$(ls app.py main.py server.py 2>/dev/null | head -1); \
              if [ -n "$FILE" ]; then \
                nohup python3 "$FILE" --port $PORT > /tmp/app.log 2>&1 & \
                sleep 2 && echo "DEPLOYED:http://\(host):$PORT"; \
              else \
                echo "NO_ENTRYPOINT"; \
              fi; \
            elif [ -f "package.json" ]; then \
              export PORT=$PORT && nohup npm start > /tmp/app.log 2>&1 & \
              sleep 3 && echo "DEPLOYED:http://\(host):$PORT"; \
            elif [ -f "index.html" ]; then \
              nohup python3 -m http.server $PORT > /tmp/app.log 2>&1 & \
              sleep 1 && echo "DEPLOYED:http://\(host):$PORT"; \
            else \
              echo "NO_APP_FOUND"; \
            fi
            """

            let output = try await claudeService.runCommand(findCmd)
            if let deployLine = output.components(separatedBy: "\n").first(where: { $0.starts(with: "DEPLOYED:") }) {
                deployedURL = String(deployLine.dropFirst("DEPLOYED:".count))
                showPreview = true

                // Notify if backgrounded
                NotificationService.notifyDeployReady(sessionTitle: session.title, url: deployedURL ?? "")
            } else {
                errorMessage = "No runnable app found in \(workDir)"
            }
        } catch {
            errorMessage = "Deploy failed: \(error.localizedDescription)"
        }

        isDeploying = false
    }

    /// Update project context
    func updateProjectContext(_ context: String) {
        session.projectContext = context.isEmpty ? nil : context
        try? modelContext.save()
    }

    /// Build a shareable summary of this session
    var shareableText: String {
        var text = "Pocket Engineer - \(session.title)\n\n"
        for msg in messages {
            let prefix = msg.role == .user ? "Me" : "Engineer"
            text += "\(prefix): \(msg.content)\n\n"
        }
        if let url = deployedURL {
            text += "Live demo: \(url)\n"
        }
        return text
    }

    private func handleEvent(_ event: ClaudeEvent, assistantMessage: ChatMessage) {
        switch event {
        case .initialized(let sessionId):
            session.remoteSessionId = sessionId

        case .assistantText(let text):
            currentStreamingText += text
            assistantMessage.content = currentStreamingText

        case .toolUse(let name, let input):
            let activity = ToolActivity(toolName: name, input: input)
            activity.message = assistantMessage
            modelContext.insert(activity)
            currentToolActivities.append(activity)

            // Notify tool activity when backgrounded
            NotificationService.notifyToolActivity(
                sessionTitle: session.title,
                tool: name,
                detail: input
            )

        case .toolResult(let output):
            if let lastTool = currentToolActivities.last {
                lastTool.output = output
            }

        case .completed(let status, _):
            if status != "success" {
                errorMessage = "Task completed with status: \(status)"
            }

        case .error(let msg):
            errorMessage = msg
            NotificationService.notifyError(sessionTitle: session.title, error: msg)
        }
    }
}
