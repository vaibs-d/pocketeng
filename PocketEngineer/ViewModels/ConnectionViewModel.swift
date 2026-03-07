import Foundation
import SwiftData
import Observation

@Observable
final class ConnectionViewModel {
    var host: String = ""
    var port: String = "22"
    var username: String = ""
    var workingDirectory: String = "~"
    var label: String = ""
    var connectionState: SSHConnectionState = .disconnected
    var errorMessage: String?
    var isImportingKey: Bool = false
    var keyImported: Bool = false
    var keyIdentifier: String?
    var isConnecting: Bool = false
    var claudeInstalled: Bool?

    /// The saved ServerConfig we are currently connected to (or about to connect to).
    var currentConfig: ServerConfig?

    private let sshService: SSHService
    private let modelContext: ModelContext

    init(sshService: SSHService, modelContext: ModelContext) {
        self.sshService = sshService
        self.modelContext = modelContext
        loadSavedConfig()
        loadDefaultsIfNeeded()
    }

    func importKey(from url: URL) {
        do {
            let keyData = try SSHKeyManager.importKey(from: url)
            let identifier = "key-\(UUID().uuidString)"
            try SSHKeyManager.storeKey(keyData, identifier: identifier)
            keyIdentifier = identifier
            keyImported = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to import key: \(error.localizedDescription)"
            keyImported = false
        }
    }

    /// Populate VM fields from an existing ServerConfig.
    @MainActor
    func loadConfig(_ config: ServerConfig) {
        host = config.host
        port = String(config.port)
        username = config.username
        workingDirectory = config.workingDirectory
        label = config.label
        keyIdentifier = config.privateKeyReference
        keyImported = true
        currentConfig = config
    }

    /// Switch to a different server: disconnect, load its config, reconnect.
    @MainActor
    func switchToServer(_ config: ServerConfig) async {
        await disconnect()
        loadConfig(config)
        await connect()
    }

    @MainActor
    func connect() async {
        guard let keyId = keyIdentifier else {
            errorMessage = "No SSH key configured"
            return
        }

        isConnecting = true
        errorMessage = nil

        do {
            let keyData = try SSHKeyManager.retrieveKey(identifier: keyId)

            try await sshService.connect(
                host: host,
                port: Int(port) ?? 22,
                username: username,
                privateKeyData: keyData
            )

            // Update existing config or create new one
            if let existing = currentConfig {
                existing.host = host
                existing.port = Int(port) ?? 22
                existing.username = username
                existing.workingDirectory = workingDirectory
                existing.label = label
                existing.lastConnectedAt = Date()
                try? modelContext.save()
            } else {
                let config = ServerConfig(
                    host: host,
                    port: Int(port) ?? 22,
                    username: username,
                    privateKeyReference: keyId,
                    label: label,
                    workingDirectory: workingDirectory
                )
                config.lastConnectedAt = Date()
                modelContext.insert(config)
                try? modelContext.save()
                currentConfig = config
            }

            connectionState = .connected
            isConnecting = false

            // Verify Claude is installed
            let claudeService = ClaudeService(sshService: sshService)
            claudeInstalled = try await claudeService.verifyClaudeInstalled()

        } catch {
            connectionState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            isConnecting = false
        }
    }

    @MainActor
    func disconnect() async {
        await sshService.disconnect()
        connectionState = .disconnected
        claudeInstalled = nil
    }

    /// Tear down stale connection and reconnect silently
    @MainActor
    func reconnectIfNeeded() async {
        // Only reconnect if we have saved config
        guard canConnect else { return }
        // Tear down any stale connection first
        await sshService.teardownIfNeeded()
        connectionState = .disconnected
        await connect()
    }

    var canConnect: Bool {
        !host.isEmpty && !username.isEmpty && keyImported && !isConnecting
    }

    func importKeyFromData(_ keyData: Data) {
        guard SSHKeyParser.isValidPrivateKey(keyData) else {
            errorMessage = "Invalid SSH key format"
            return
        }
        do {
            let identifier = "key-embedded"
            try SSHKeyManager.storeKey(keyData, identifier: identifier)
            keyIdentifier = identifier
            keyImported = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to store key: \(error.localizedDescription)"
        }
    }

    private func loadSavedConfig() {
        let persistence = PersistenceService(modelContext: modelContext)
        if let config = persistence.fetchServerConfig() {
            host = config.host
            port = String(config.port)
            username = config.username
            workingDirectory = config.workingDirectory
            label = config.label
            keyIdentifier = config.privateKeyReference
            keyImported = true
            currentConfig = config
        }
    }

    private func loadDefaultsIfNeeded() {
        // Pre-configured EC2 instance defaults
        if host.isEmpty {
            host = DefaultEC2Config.host
            port = String(DefaultEC2Config.port)
            username = DefaultEC2Config.username
            workingDirectory = DefaultEC2Config.workingDirectory
            label = DefaultEC2Config.label

            // Import embedded SSH key if not already imported
            if !keyImported, let keyData = DefaultEC2Config.sshKeyData {
                importKeyFromData(keyData)
            }
        }
    }
}
