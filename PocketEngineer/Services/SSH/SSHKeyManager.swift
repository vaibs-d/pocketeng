import Foundation
import Security

struct SSHKeyManager {
    private static let service = "com.pocketengineer.sshkeys"

    static func storeKey(_ keyData: Data, identifier: String) throws {
        // Delete existing key with same identifier first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    static func retrieveKey(identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.retrieveFailed(status)
        }
        return data
    }

    static func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    static func importKey(from url: URL) throws -> Data {
        guard url.startAccessingSecurityScopedResource() else {
            throw KeychainError.invalidKeyFormat
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let keyData = try Data(contentsOf: url)
        guard SSHKeyParser.isValidPrivateKey(keyData) else {
            throw KeychainError.invalidKeyFormat
        }
        return keyData
    }
}
