import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if message.role == .system {
                systemMessageView
            } else {
                logEntryView
            }
        }
    }

    private var logEntryView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Role label + timestamp
            HStack(spacing: 6) {
                Text(message.role == .user ? "you" : "claude")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(message.role == .user ? .accent : .textSecondary)

                Text(message.timestamp, style: .time)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.textTertiary)

                if message.state == .streaming {
                    ProgressView()
                        .scaleEffect(0.5)
                        .tint(.accent)
                }
                if message.state == .error {
                    Image(systemName: "xmark.circle")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }

            // Content
            if message.content.isEmpty && message.state == .streaming {
                Text("...")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.textTertiary)
            } else if message.role == .user {
                Text(message.content)
                    .font(.system(.subheadline))
                    .foregroundColor(.textPrimary)
                    .textSelection(.enabled)
            } else {
                MarkdownContentView(content: message.content, role: message.role)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(message.role == .user ? Color.white.opacity(0.04) : Color.clear)
    }

    private var systemMessageView: some View {
        HStack(spacing: 6) {
            Text("--")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textTertiary)
            Text(message.content)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
