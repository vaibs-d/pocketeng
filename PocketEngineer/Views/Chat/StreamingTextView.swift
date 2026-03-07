import SwiftUI

struct StreamingTextView: View {
    let text: String
    let isActive: Bool

    init(text: String, isActive: Bool = true) {
        self.text = text
        self.isActive = isActive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("claude")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                if isActive {
                    ProgressView()
                        .scaleEffect(0.5)
                        .tint(.accent)
                }
            }

            if text.isEmpty {
                Text("working...")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.textTertiary)
            } else {
                MarkdownContentView(content: text, role: .assistant)
                    .textSelection(.enabled)

                if isActive {
                    CursorBlink()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct CursorBlink: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color.accent)
            .frame(width: 8, height: 2)
            .opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(), value: visible)
            .onAppear { visible = false }
    }
}

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.textTertiary)
                    .frame(width: 4, height: 4)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}
