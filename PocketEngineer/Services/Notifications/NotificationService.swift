import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#endif

struct NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    // MARK: - Agent Events

    static func notifyTaskComplete(sessionTitle: String, summary: String? = nil) {
        guard isBackgrounded else { return }

        let content = UNMutableNotificationContent()
        content.title = "task complete"
        content.body = summary ?? "\"\(sessionTitle)\" finished"
        content.sound = .default

        send(content)
    }

    static func notifyError(sessionTitle: String, error: String) {
        guard isBackgrounded else { return }

        let content = UNMutableNotificationContent()
        content.title = "error"
        content.body = "\(sessionTitle): \(String(error.prefix(120)))"
        content.sound = UNNotificationSound.defaultCritical

        send(content)
    }

    static func notifyDeployReady(sessionTitle: String, url: String) {
        guard isBackgrounded else { return }

        let content = UNMutableNotificationContent()
        content.title = "live"
        content.body = "\(sessionTitle) deployed"
        content.sound = .default

        send(content)
    }

    static func notifyToolActivity(sessionTitle: String, tool: String, detail: String) {
        guard isBackgrounded else { return }

        let content = UNMutableNotificationContent()
        content.title = sessionTitle
        content.body = "\(tool): \(String(detail.prefix(100)))"
        content.sound = nil

        // Replace previous tool notification to avoid spam
        let request = UNNotificationRequest(
            identifier: "tool-\(sessionTitle)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Legacy

    static func notifyBuildComplete(sessionTitle: String) {
        notifyTaskComplete(sessionTitle: sessionTitle)
    }

    // MARK: - Helpers

    private static func send(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static var isBackgrounded: Bool {
        #if os(iOS)
        return UIApplication.shared.applicationState != .active
        #else
        return false
        #endif
    }
}
