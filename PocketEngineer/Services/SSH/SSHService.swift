import Foundation
import Citadel
import NIOSSH
import NIO
import Crypto

actor SSHService {
    private var client: SSHClient?
    private(set) var state: SSHConnectionState = .disconnected

    private var keepAliveTask: Task<Void, Never>?

    func connect(
        host: String,
        port: Int,
        username: String,
        privateKeyData: Data
    ) async throws {
        state = .connecting

        do {
            guard let keyString = String(data: privateKeyData, encoding: .utf8) else {
                throw SSHError.keyParsingFailed("Could not decode key data as UTF-8")
            }

            let trimmedKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
            let capturedUsername = username
            let authMethod: SSHAuthenticationMethod

            if trimmedKey.contains("BEGIN OPENSSH PRIVATE KEY") {
                // Try Ed25519 first, fall back to RSA
                if let ed25519Key = try? Curve25519.Signing.PrivateKey(sshEd25519: trimmedKey) {
                    authMethod = .ed25519(
                        username: capturedUsername,
                        privateKey: ed25519Key
                    )
                } else if let rsaKey = try? Insecure.RSA.PrivateKey(sshRsa: trimmedKey) {
                    authMethod = .rsa(
                        username: capturedUsername,
                        privateKey: rsaKey
                    )
                } else {
                    throw SSHError.keyParsingFailed("Could not parse key as Ed25519 or RSA")
                }
            } else if trimmedKey.contains("BEGIN RSA PRIVATE KEY") || trimmedKey.contains("BEGIN PRIVATE KEY") {
                let rsaKey = try Insecure.RSA.PrivateKey(sshRsa: trimmedKey)
                authMethod = .rsa(
                    username: capturedUsername,
                    privateKey: rsaKey
                )
            } else {
                throw SSHError.keyParsingFailed("Unsupported key format")
            }

            let settings = SSHClientSettings(
                host: host,
                port: port,
                authenticationMethod: { authMethod },
                hostKeyValidator: .acceptAnything()
            )

            client = try await SSHClient.connect(to: settings)
            state = .connected
            startKeepAlive()

        } catch let error as SSHError {
            state = .error(error.localizedDescription)
            throw error
        } catch {
            let msg = String(describing: error)
            let sshError = SSHError.connectionFailed(msg)
            state = .error(msg)
            throw sshError
        }
    }

    func executeStreaming(
        command: String,
        onOutput: @escaping @Sendable (String, Bool) -> Void
    ) async throws {
        guard let client else {
            throw SSHError.notConnected
        }

        do {
            let streams = try await client.executeCommandStream(command)

            for try await event in streams {
                switch event {
                case .stdout(var buffer):
                    if let str = buffer.readString(length: buffer.readableBytes) {
                        onOutput(str, false)
                    }
                case .stderr(var buffer):
                    if let str = buffer.readString(length: buffer.readableBytes) {
                        onOutput(str, true)
                    }
                }
            }
        } catch {
            // If the channel/connection died, update state
            if !isConnected { handleDisconnection() }
            throw SSHError.connectionFailed(String(describing: error))
        }
    }

    func executeCommand(_ command: String) async throws -> String {
        guard let client else {
            throw SSHError.notConnected
        }

        do {
            var output = try await client.executeCommand(command)
            return output.readString(length: output.readableBytes) ?? ""
        } catch {
            throw SSHError.connectionFailed(String(describing: error))
        }
    }

    func disconnect() async {
        keepAliveTask?.cancel()
        keepAliveTask = nil
        if let c = client {
            client = nil
            do { try await c.close() } catch { /* already dead, ignore */ }
        }
        state = .disconnected
    }

    /// Silently tear down a stale connection without throwing
    func teardownIfNeeded() async {
        guard client != nil else { return }
        keepAliveTask?.cancel()
        keepAliveTask = nil
        if let c = client {
            client = nil
            do { try await c.close() } catch { /* ignore */ }
        }
        state = .disconnected
    }

    var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    private func startKeepAlive() {
        keepAliveTask?.cancel()
        keepAliveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                do {
                    _ = try await self.executeCommand("echo keepalive")
                } catch {
                    self.handleDisconnection()
                    break
                }
            }
        }
    }

    private func handleDisconnection() {
        state = .error("Connection lost")
        client = nil
    }
}
