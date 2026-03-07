import SwiftUI

struct SessionStatusBanner: View {
    let status: SessionStatus
    let errorMessage: String?

    init(status: SessionStatus, errorMessage: String? = nil) {
        self.status = status
        self.errorMessage = errorMessage
    }

    var body: some View {
        if status == .active || status == .error {
            HStack(spacing: 6) {
                if status == .active {
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 6, height: 6)
                    Text("running")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.accent)
                } else if status == .error {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text(errorMessage ?? "error")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.surface)
        }
    }
}
