import SwiftUI

struct ConnectionStatusView: View {
    let state: SSHConnectionState
    var serverLabel: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.textSecondary)

            if let label = serverLabel, !label.isEmpty {
                Text("· \(label)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.surface)
    }

    private var statusColor: Color {
        switch state {
        case .connected: return .accent
        case .connecting: return .yellow
        case .disconnected: return .textTertiary
        case .error: return .red
        }
    }

    private var statusText: String {
        switch state {
        case .connected: return "connected"
        case .connecting: return "connecting..."
        case .disconnected: return "disconnected"
        case .error(let msg): return "error: \(msg)"
        }
    }
}
