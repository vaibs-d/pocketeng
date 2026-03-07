import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(session.status.rawValue)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)

                    Text(session.updatedAt, style: .relative)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                }

                if let lastMessage = session.sortedMessages.last {
                    Text(lastMessage.content)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(session.messages.count)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch session.status {
        case .active: return .accent
        case .idle: return .textTertiary
        case .completed: return .textMuted
        case .error: return .red
        }
    }
}
