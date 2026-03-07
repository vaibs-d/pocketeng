import Foundation

struct SSHKeyParser {
    static func isValidPrivateKey(_ data: Data) -> Bool {
        guard let content = String(data: data, encoding: .utf8) else {
            return false
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("-----BEGIN") && trimmed.contains("PRIVATE KEY-----")
            || trimmed.hasPrefix("-----BEGIN OPENSSH PRIVATE KEY-----")
    }

    static func keyType(_ data: Data) -> String? {
        guard let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        if content.contains("BEGIN RSA PRIVATE KEY") {
            return "rsa"
        } else if content.contains("BEGIN EC PRIVATE KEY") {
            return "ecdsa"
        } else if content.contains("BEGIN OPENSSH PRIVATE KEY") {
            return "openssh"
        } else if content.contains("BEGIN PRIVATE KEY") {
            return "pkcs8"
        }
        return nil
    }
}
