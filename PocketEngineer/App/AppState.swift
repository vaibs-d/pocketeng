import Foundation
import Observation

@Observable
final class AppState {
    var selectedSession: Session?
    var connectionState: SSHConnectionState = .disconnected
    var currentServerConfig: ServerConfig?

    func selectSession(_ session: Session) {
        selectedSession = session
    }

    func clearSelection() {
        selectedSession = nil
    }
}
