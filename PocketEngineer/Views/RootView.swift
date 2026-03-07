import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var serverConfigs: [ServerConfig]
    @State private var hasCompletedOnboarding = false

    var body: some View {
        if serverConfigs.isEmpty && !hasCompletedOnboarding {
            OnboardingView { host, sshKeyData in
                saveProvisionedServer(host: host, sshKeyData: sshKeyData)
            }
        } else {
            ContentView()
        }
    }

    private func saveProvisionedServer(host: String, sshKeyData: Data) {
        // Store the SSH key in Keychain
        let keyIdentifier = "key-provisioned-\(UUID().uuidString.prefix(8))"
        do {
            try SSHKeyManager.storeKey(sshKeyData, identifier: keyIdentifier)
        } catch {
            print("Failed to store SSH key: \(error)")
            return
        }

        // Create and save a ServerConfig
        let config = ServerConfig(
            host: host,
            port: 22,
            username: "ec2-user",
            privateKeyReference: keyIdentifier,
            label: host,
            workingDirectory: "~/projects"
        )
        modelContext.insert(config)
        try? modelContext.save()

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
