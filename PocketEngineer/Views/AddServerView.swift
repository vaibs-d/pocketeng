import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var host = ""
    @State private var label = ""
    @State private var sshKeyText = ""
    @State private var errorMessage: String?
    @State private var showScanner = false

    let onComplete: (String, Data, String) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("add server")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .padding(.top)

                    // QR scan button
                    Button {
                        showScanner = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("scan QR code")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.semibold)
                                Text("from pocket-engineer --qr")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.textPrimary)
                        .padding(14)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.surfaceBorder, lineWidth: 1)
                        )
                    }
                    #if os(iOS)
                    .sheet(isPresented: $showScanner) {
                        QRScannerView { scannedData in
                            showScanner = false
                            handleQRCode(scannedData)
                        }
                    }
                    #endif

                    // Divider
                    HStack {
                        Rectangle().fill(Color.surfaceBorder).frame(height: 1)
                        Text("or")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.textTertiary)
                        Rectangle().fill(Color.surfaceBorder).frame(height: 1)
                    }

                    // Manual: host
                    VStack(alignment: .leading, spacing: 6) {
                        Text("host")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.textTertiary)
                        TextField("54.123.45.67", text: $host)
                            .textFieldStyle(.plain)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.textPrimary)
                            .padding(12)
                            .background(Color.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.surfaceBorder, lineWidth: 1)
                            )
                            #if os(iOS)
                            .autocapitalization(.none)
                            .keyboardType(.asciiCapable)
                            #endif
                    }

                    // Manual: label
                    VStack(alignment: .leading, spacing: 6) {
                        Text("label (optional)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.textTertiary)
                        TextField("e.g. work, personal", text: $label)
                            .textFieldStyle(.plain)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.textPrimary)
                            .padding(12)
                            .background(Color.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.surfaceBorder, lineWidth: 1)
                            )
                    }

                    // Manual: SSH key
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ssh private key")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.textTertiary)
                        TextEditor(text: $sshKeyText)
                            .font(.system(.caption2, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.textPrimary)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.surfaceBorder, lineWidth: 1)
                            )
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.red)
                    }

                    // Add button
                    Button {
                        addManually()
                    } label: {
                        Text("add server")
                            .font(.system(.subheadline, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.surface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canAdd ? Color.textPrimary : Color.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .disabled(!canAdd)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.surface)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var canAdd: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !sshKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleQRCode(_ data: String) {
        guard data.hasPrefix("pe://") else {
            errorMessage = "invalid QR code format"
            return
        }
        let stripped = String(data.dropFirst(5)) // remove pe://
        let parts = stripped.components(separatedBy: "?")
        let hostPart = parts.first?.components(separatedBy: ":").first ?? ""

        host = hostPart
        if parts.count > 1, let query = parts.last, query.hasPrefix("key=") {
            let b64Key = String(query.dropFirst(4))
            if let keyData = Data(base64Encoded: b64Key) {
                // QR scan has everything — add immediately
                let serverLabel = label.isEmpty ? hostPart : label
                onComplete(hostPart, keyData, serverLabel)
                dismiss()
                return
            }
        }
        errorMessage = "QR code missing SSH key"
    }

    private func addManually() {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = sshKeyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, !trimmedKey.isEmpty,
              let keyData = trimmedKey.data(using: .utf8) else {
            errorMessage = "host and ssh key are required"
            return
        }
        guard SSHKeyParser.isValidPrivateKey(keyData) else {
            errorMessage = "invalid SSH key format"
            return
        }
        let serverLabel = label.isEmpty ? trimmedHost : label
        onComplete(trimmedHost, keyData, serverLabel)
        dismiss()
    }
}
