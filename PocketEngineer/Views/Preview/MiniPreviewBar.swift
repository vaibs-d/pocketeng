import SwiftUI

/// Persistent mini bar shown in chat when a live app is deployed
struct MiniPreviewBar: View {
    let url: String
    let onTap: () -> Void
    let onRefresh: () -> Void

    @State private var isLive = true

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isLive ? Color.accent : Color.yellow)
                        .frame(width: 6, height: 6)
                        .modifier(LivePulse())

                    Text("live")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }

                // URL
                Text(url)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // Quick actions
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textTertiary)
                        .padding(4)
                }

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accent.opacity(0.06))
            .overlay(
                Rectangle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LivePulse: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
                    .scaleEffect(pulsing ? 2.0 : 1.0)
                    .opacity(pulsing ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: pulsing
                    )
            )
            .onAppear { pulsing = true }
    }
}
