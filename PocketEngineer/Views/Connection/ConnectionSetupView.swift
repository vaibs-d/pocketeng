import SwiftUI
import UniformTypeIdentifiers

struct ConnectionSetupView: View {
    @Bindable var viewModel: ConnectionViewModel
    @State private var showFileImporter = false

    var body: some View {
        Form {
            Section("Server") {
                TextField("Host", text: $viewModel.host)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif

                TextField("Port", text: $viewModel.port)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                TextField("Username", text: $viewModel.username)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                TextField("Working Directory", text: $viewModel.workingDirectory)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .font(.system(.body, design: .monospaced))

                TextField("Label (optional)", text: $viewModel.label)
            }

            Section("SSH Key") {
                Button {
                    showFileImporter = true
                } label: {
                    HStack {
                        Image(systemName: viewModel.keyImported ? "checkmark.circle.fill" : "key.fill")
                            .foregroundColor(viewModel.keyImported ? .green : .accentColor)
                        Text(viewModel.keyImported ? "Key Imported" : "Import Private Key")
                    }
                }

                if viewModel.keyImported {
                    Text("Stored securely in Keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                if viewModel.isConnecting {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Connecting...")
                    }
                } else if case .connected = viewModel.connectionState {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected")
                    }

                    if let installed = viewModel.claudeInstalled {
                        HStack {
                            Image(systemName: installed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(installed ? .green : .red)
                            Text(installed ? "Claude CLI detected" : "Claude CLI not found")
                        }
                        .font(.caption)
                    }

                    Button("Disconnect", role: .destructive) {
                        Task { await viewModel.disconnect() }
                    }
                } else {
                    Button("Connect") {
                        Task { await viewModel.connect() }
                    }
                    .disabled(!viewModel.canConnect)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Connection")
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.data, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importKey(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
