import SwiftUI

struct InputBarView: View {
    @Binding var text: String
    let isStreaming: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    #if os(iOS)
    @State private var speechService = SpeechService()
    #endif

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.surfaceBorder)
                .frame(height: 1)

            #if os(iOS)
            // Voice recording indicator
            if speechService.isRecording {
                recordingBanner
            }
            #endif

            HStack(alignment: .bottom, spacing: 8) {
                Text(">")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(isStreaming ? .textTertiary : .accent)
                    .padding(.bottom, 10)

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...8)
                    .textFieldStyle(.plain)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 10)
                    .focused($isFocused)
                    .disabled(isStreaming)
                    .onSubmit {
                        if !isStreaming && !trimmedText.isEmpty {
                            onSend()
                        }
                    }

                if isStreaming {
                    Button(action: onCancel) {
                        Text("^C")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.bottom, 6)
                } else {
                    HStack(spacing: 6) {
                        #if os(iOS)
                        micButton
                        #endif

                        Button(action: onSend) {
                            Image(systemName: "return")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(trimmedText.isEmpty ? .textTertiary : .accent)
                                .padding(8)
                                .background(trimmedText.isEmpty ? Color.clear : Color.accent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .disabled(trimmedText.isEmpty)
                    }
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.surface)
        }
        #if os(iOS)
        .onAppear {
            speechService.requestAuthorization()
        }
        .onChange(of: speechService.transcribedText) { _, newValue in
            if !newValue.isEmpty {
                text = newValue
            }
        }
        #endif
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Voice Input

    #if os(iOS)
    private var micButton: some View {
        Button {
            if speechService.isRecording {
                speechService.stopRecording()
            } else {
                speechService.startRecording()
            }
        } label: {
            Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(speechService.isRecording ? .red : .textSecondary)
                .padding(8)
                .background(speechService.isRecording ? Color.red.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .disabled(!speechService.isAuthorized)
    }

    private var recordingBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .modifier(PulseModifier())

            Text("listening...")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.red.opacity(0.8))

            Spacer()

            if !speechService.transcribedText.isEmpty {
                Text(speechService.transcribedText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.05))
    }
    #endif
}

// MARK: - Pulse animation

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 0.8)
            .opacity(isPulsing ? 1.0 : 0.5)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
