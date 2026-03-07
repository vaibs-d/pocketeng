import Foundation
import CryptoKit

/// Minimal AWS Signature V4 implementation for making direct API calls from iOS
struct AWSSigV4 {
    let accessKey: String
    let secretKey: String
    let region: String
    let service: String

    func signedRequest(
        method: String = "GET",
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let amzDate = dateFormatter.string(from: now)

        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: now)

        let bodyHash = sha256Hex(body ?? Data())

        request.setValue(amzDate, forHTTPHeaderField: "X-Amz-Date")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Amz-Content-Sha256")
        request.setValue(url.host ?? "", forHTTPHeaderField: "Host")

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Canonical request
        let canonicalURI = url.path.isEmpty ? "/" : url.path
        // AWS SigV4 requires query params sorted by key
        let canonicalQueryString: String = {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems, !queryItems.isEmpty else {
                return ""
            }
            return queryItems
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\(Self.uriEncode($0.value ?? ""))" }
                .joined(separator: "&")
        }()

        let signedHeaderKeys = request.allHTTPHeaderFields?
            .keys
            .map { $0.lowercased() }
            .sorted() ?? []
        let signedHeaders = signedHeaderKeys.joined(separator: ";")

        let canonicalHeaders = signedHeaderKeys.map { key in
            let value = request.allHTTPHeaderFields?.first(where: { $0.key.lowercased() == key })?.value ?? ""
            return "\(key):\(value.trimmingCharacters(in: .whitespaces))"
        }.joined(separator: "\n") + "\n"

        let canonicalRequest = [
            method,
            canonicalURI,
            canonicalQueryString,
            canonicalHeaders,
            signedHeaders,
            bodyHash
        ].joined(separator: "\n")

        // String to sign
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            sha256Hex(canonicalRequest.data(using: .utf8)!)
        ].joined(separator: "\n")

        // Signing key
        let kDate = hmacSHA256(key: "AWS4\(secretKey)".data(using: .utf8)!, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmacSHA256(key: kDate, data: region.data(using: .utf8)!)
        let kService = hmacSHA256(key: kRegion, data: service.data(using: .utf8)!)
        let kSigning = hmacSHA256(key: kService, data: "aws4_request".data(using: .utf8)!)

        let signature = hmacSHA256Hex(key: kSigning, data: stringToSign.data(using: .utf8)!)

        let authorization = "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        return request
    }

    // MARK: - Helpers

    static func uriEncode(_ string: String) -> String {
        // AWS SigV4 URI encoding: encode everything except unreserved chars
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func hmacSHA256(key: Data, data: Data) -> Data {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
        return Data(hmac)
    }

    private func hmacSHA256Hex(key: Data, data: Data) -> String {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
        return Data(hmac).map { String(format: "%02x", $0) }.joined()
    }
}
