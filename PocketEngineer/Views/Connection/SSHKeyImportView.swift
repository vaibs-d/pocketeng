import SwiftUI
import UniformTypeIdentifiers

struct SSHKeyImportView: View {
    let onImport: (URL) -> Void
    @State private var showFileImporter = false
    @State private var showPasteSheet = false
    @State private var pastedKey = ""

    var body: some View {
        VStack(spacing: 16) {
            Button {
                showFileImporter = true
            } label: {
                Label("Import from Files", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                showPasteSheet = true
            } label: {
                Label("Paste Key", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.data, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                onImport(url)
            }
        }
        .sheet(isPresented: $showPasteSheet) {
            NavigationStack {
                TextEditor(text: $pastedKey)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .navigationTitle("Paste SSH Key")
                    .iOSNavigationBarTitleDisplayMode()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showPasteSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Import") {
                                savePastedKey()
                                showPasteSheet = false
                            }
                            .disabled(pastedKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private func savePastedKey() {
        let keyData = Data(pastedKey.utf8)
        guard SSHKeyParser.isValidPrivateKey(keyData) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pasted_key")
        try? keyData.write(to: tempURL)
        onImport(tempURL)
    }
}
