import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \ServerConfig.lastConnectedAt, order: .reverse)
    private var serverConfigs: [ServerConfig]
    @State private var appState = AppState()
    @State private var sshService = SSHService()
    @State private var connectionVM: ConnectionViewModel?
    @State private var sessionListVM: SessionListViewModel?
    @State private var showConnectionSetup = false
    @State private var showPickUpSession = false
    @State private var showAddServer = false
    @State private var selectedSessionId: UUID?
    @State private var navigationPath = NavigationPath()
    @State private var pendingInitialPrompt: String?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainListView
                .navigationTitle("Pocket Engineer")
                .navigationDestination(for: UUID.self) { sessionId in
                    if let session = sessionListVM?.sessions.first(where: { $0.id == sessionId }) {
                        let vm = ChatViewModel(
                            session: session,
                            claudeService: ClaudeService(sshService: sshService),
                            modelContext: modelContext
                        )
                        ChatView(viewModel: vm)
                            .task {
                                if let prompt = pendingInitialPrompt {
                                    pendingInitialPrompt = nil
                                    await vm.autoSendInitialPrompt(prompt)
                                }
                            }
                    }
                }
        }
        .tint(.accent)
        .preferredColorScheme(.dark)
        .onAppear {
            if connectionVM == nil {
                connectionVM = ConnectionViewModel(sshService: sshService, modelContext: modelContext)
            }
            if sessionListVM == nil {
                sessionListVM = SessionListViewModel(modelContext: modelContext)
            }
            // Set active server from the loaded config
            if appState.activeServerConfig == nil, let config = connectionVM?.currentConfig {
                appState.activeServerConfig = config
            }
        }
        .task {
            if let vm = connectionVM, vm.canConnect, vm.connectionState == .disconnected {
                await vm.connect()
            }
            // Filter sessions for active server
            if let config = appState.activeServerConfig {
                sessionListVM?.fetchSessions(for: config)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard let vm = connectionVM else { return }
            switch newPhase {
            case .background:
                Task { await sshService.teardownIfNeeded() }
                vm.connectionState = .disconnected
            case .active:
                if vm.canConnect && vm.connectionState != .connected && vm.connectionState != .connecting {
                    Task { await vm.reconnectIfNeeded() }
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var mainListView: some View {
        VStack(spacing: 0) {
            // Connection status with server label
            if let vm = connectionVM {
                ConnectionStatusView(
                    state: vm.connectionState,
                    serverLabel: appState.activeServerConfig?.label
                )
            }

            // Server picker (only when multiple servers exist)
            if serverConfigs.count > 1 {
                serverPicker
            }

            if let listVM = sessionListVM {
                if listVM.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text(">_")
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundStyle(Color.textTertiary)
                        Text("No sessions")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        Text("Tap + to start")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.surface)
                } else {
                    List {
                        ForEach(listVM.sessions, id: \.id) { session in
                            NavigationLink(value: session.id) {
                                SessionRowView(session: session)
                            }
                            .listRowBackground(Color.surface)
                        }
                        .onDelete { offsets in
                            listVM.deleteSessions(at: offsets)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.surface)
                }
            }
        }
        .background(Color.surface)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 14) {
                    Button {
                        showConnectionSetup = true
                    } label: {
                        Image(systemName: connectionIcon)
                            .font(.system(size: 14))
                            .foregroundColor(connectionColor)
                    }

                    Button {
                        showPickUpSession = true
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }

                    Button {
                        sessionListVM?.showNewSessionSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showConnectionSetup) {
            if let vm = connectionVM {
                NavigationStack {
                    ConnectionSetupView(viewModel: vm)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showConnectionSetup = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { sessionListVM?.showNewSessionSheet ?? false },
            set: { sessionListVM?.showNewSessionSheet = $0 }
        )) {
            NewSessionView { title, initialPrompt in
                if let listVM = sessionListVM {
                    let session = listVM.createSession(
                        title: title,
                        serverConfig: appState.activeServerConfig
                    )
                    pendingInitialPrompt = initialPrompt
                    navigationPath.append(session.id)
                }
            }
        }
        .sheet(isPresented: $showPickUpSession) {
            PickUpSessionView(sshService: sshService) { remoteSession in
                pickUpRemoteSession(remoteSession)
            }
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView { host, sshKeyData, serverLabel in
                saveNewServer(host: host, sshKeyData: sshKeyData, label: serverLabel)
            }
        }
    }

    // MARK: - Server Picker

    @ViewBuilder
    private var serverPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(serverConfigs, id: \.id) { config in
                    let isActive = appState.activeServerConfig?.id == config.id
                    Button {
                        Task { await switchToServer(config) }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isActive ? Color.accent : Color.textTertiary)
                                .frame(width: 6, height: 6)
                            Text(config.label.isEmpty ? config.host : config.label)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(isActive ? .accent : .textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isActive ? Color.accent.opacity(0.1) : Color.surfaceRaised)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                isActive ? Color.accent.opacity(0.3) : Color.surfaceBorder,
                                lineWidth: 1
                            )
                        )
                    }
                }

                // Add server button
                Button {
                    showAddServer = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Color.surfaceRaised)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.surfaceBorder, lineWidth: 1))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Actions

    private func switchToServer(_ config: ServerConfig) async {
        appState.switchServer(to: config)
        await connectionVM?.switchToServer(config)
        sessionListVM?.fetchSessions(for: config)
    }

    private func pickUpRemoteSession(_ remote: RemoteSession) {
        guard let listVM = sessionListVM else { return }
        let session = listVM.createSession(
            title: remote.displayTitle,
            serverConfig: appState.activeServerConfig
        )
        session.remoteSessionId = remote.id
        try? modelContext.save()
        navigationPath.append(session.id)
    }

    private func saveNewServer(host: String, sshKeyData: Data, label: String) {
        let keyIdentifier = "key-provisioned-\(UUID().uuidString.prefix(8))"
        do {
            try SSHKeyManager.storeKey(sshKeyData, identifier: keyIdentifier)
        } catch {
            print("Failed to store SSH key: \(error)")
            return
        }

        let config = ServerConfig(
            host: host,
            port: 22,
            username: "ec2-user",
            privateKeyReference: keyIdentifier,
            label: label,
            workingDirectory: "~/projects"
        )
        modelContext.insert(config)
        try? modelContext.save()

        Task { await switchToServer(config) }
    }

    // MARK: - Helpers

    private var connectionIcon: String {
        switch connectionVM?.connectionState ?? .disconnected {
        case .connected: return "bolt.fill"
        case .connecting: return "bolt.badge.clock"
        case .disconnected: return "bolt.slash"
        case .error: return "bolt.trianglebadge.exclamationmark"
        }
    }

    private var connectionColor: Color {
        switch connectionVM?.connectionState ?? .disconnected {
        case .connected: return .accent
        case .connecting: return .yellow
        case .disconnected: return .textTertiary
        case .error: return .red
        }
    }
}
