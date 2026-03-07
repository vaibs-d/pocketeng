import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    @State private var sshService = SSHService()
    @State private var connectionVM: ConnectionViewModel?
    @State private var sessionListVM: SessionListViewModel?
    @State private var showConnectionSetup = false
    @State private var showPickUpSession = false
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
        }
        .task {
            if let vm = connectionVM, vm.canConnect, vm.connectionState == .disconnected {
                await vm.connect()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard let vm = connectionVM else { return }
            switch newPhase {
            case .background:
                // Tear down SSH cleanly so we don't get NIOSSHError on resume
                Task { await sshService.teardownIfNeeded() }
                vm.connectionState = .disconnected
            case .active:
                // Reconnect when app comes back to foreground
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
            if let vm = connectionVM {
                ConnectionStatusView(state: vm.connectionState)
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
                    let serverConfig = PersistenceService(modelContext: modelContext).fetchServerConfig()
                    let session = listVM.createSession(title: title, serverConfig: serverConfig)
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
    }

    private func pickUpRemoteSession(_ remote: RemoteSession) {
        guard let listVM = sessionListVM else { return }
        let serverConfig = PersistenceService(modelContext: modelContext).fetchServerConfig()
        let session = listVM.createSession(
            title: remote.displayTitle,
            serverConfig: serverConfig
        )
        session.remoteSessionId = remote.id
        try? modelContext.save()
        navigationPath.append(session.id)
    }

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
