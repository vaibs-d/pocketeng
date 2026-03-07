import Foundation
import Observation

@Observable
final class AppState {
    var selectedSession: Session?
    var connectionState: SSHConnectionState = .disconnected
    var activeServerConfig: ServerConfig?

    func selectSession(_ session: Session) {
        selectedSession = session
    }

    func clearSelection() {
        selectedSession = nil
    }

    func switchServer(to config: ServerConfig) {
        activeServerConfig = config
    }
}
