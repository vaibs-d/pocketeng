import SwiftUI

struct ToolActivityView: View {
    let activity: ToolActivity
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(activity.toolName)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.accent)

                    Text(activity.input)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if let duration = activity.durationMs {
                        Text("\(duration)ms")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.textTertiary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)

            if isExpanded, let output = activity.output, !output.isEmpty {
                ScrollView {
                    Text(output)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 200)
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.surfaceBorder, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.leading, 12)
    }
}
