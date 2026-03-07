import XCTest
@testable import PocketEngineer

// MARK: - ANSIStripper Tests

final class ANSIStripperTests: XCTestCase {

    func testStripColorCodes() {
        let input = "\u{1B}[32mHello\u{1B}[0m World"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "Hello World")
    }

    func testStripBoldCode() {
        let input = "\u{1B}[1mBold\u{1B}[0m"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "Bold")
    }

    func testStripMultipleCodes() {
        let input = "\u{1B}[31mred\u{1B}[0m \u{1B}[32mgreen\u{1B}[0m \u{1B}[34mblue\u{1B}[0m"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "red green blue")
    }

    func testStripNoAnsiCodes() {
        let input = "plain text with no escape codes"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "plain text with no escape codes")
    }

    func testStripEmptyString() {
        let result = ANSIStripper.strip("")
        XCTAssertEqual(result, "")
    }

    func testStripComplexEscapeSequence() {
        // SGR with multiple parameters
        let input = "\u{1B}[1;31;40mStyled\u{1B}[0m"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "Styled")
    }

    func testStripOSCSequence() {
        // Operating System Command (title setting)
        let input = "\u{1B}]0;Window Title\u{07}Content"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "Content")
    }

    func testStripCharacterSetSequence() {
        let input = "\u{1B}(BContent"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, "Content")
    }

    func testPreservesJSONContent() {
        let input = "{\"key\":\"value\",\"number\":42}"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, input, "JSON without ANSI codes should be unchanged")
    }

    func testStripAnsiAroundJSON() {
        let json = "{\"type\":\"system\",\"session_id\":\"abc\"}"
        let input = "\u{1B}[32m\(json)\u{1B}[0m"
        let result = ANSIStripper.strip(input)
        XCTAssertEqual(result, json)
    }
}

// MARK: - SSHKeyParser Tests

final class SSHKeyParserTests: XCTestCase {

    // MARK: - isValidPrivateKey

    func testValidRSAKey() {
        let key = """
        -----BEGIN RSA PRIVATE KEY-----
        MIIEowIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF1PbnGMH7gVkZGmTdblA
        -----END RSA PRIVATE KEY-----
        """
        let data = Data(key.utf8)
        XCTAssertTrue(SSHKeyParser.isValidPrivateKey(data))
    }

    func testValidOpenSSHKey() {
        let key = """
        -----BEGIN OPENSSH PRIVATE KEY-----
        b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
        -----END OPENSSH PRIVATE KEY-----
        """
        let data = Data(key.utf8)
        XCTAssertTrue(SSHKeyParser.isValidPrivateKey(data))
    }

    func testValidECKey() {
        let key = """
        -----BEGIN EC PRIVATE KEY-----
        MHQCAQEEIEuGwCTFAJb2aANaXnPg+SOME+DATA
        -----END EC PRIVATE KEY-----
        """
        let data = Data(key.utf8)
        XCTAssertTrue(SSHKeyParser.isValidPrivateKey(data))
    }

    func testValidPKCS8Key() {
        let key = """
        -----BEGIN PRIVATE KEY-----
        MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg
        -----END PRIVATE KEY-----
        """
        let data = Data(key.utf8)
        XCTAssertTrue(SSHKeyParser.isValidPrivateKey(data))
    }

    func testInvalidPublicKey() {
        let key = """
        -----BEGIN PUBLIC KEY-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
        -----END PUBLIC KEY-----
        """
        let data = Data(key.utf8)
        XCTAssertFalse(SSHKeyParser.isValidPrivateKey(data), "Public keys should not be valid")
    }

    func testInvalidRandomString() {
        let data = Data("not a key at all".utf8)
        XCTAssertFalse(SSHKeyParser.isValidPrivateKey(data))
    }

    func testInvalidEmptyData() {
        let data = Data()
        XCTAssertFalse(SSHKeyParser.isValidPrivateKey(data))
    }

    func testValidKeyWithWhitespace() {
        let key = """

          -----BEGIN OPENSSH PRIVATE KEY-----
          b3BlbnNzaC1rZXktdjEAAAAABG5vbmU=
          -----END OPENSSH PRIVATE KEY-----

        """
        let data = Data(key.utf8)
        XCTAssertTrue(SSHKeyParser.isValidPrivateKey(data))
    }

    // MARK: - keyType

    func testKeyTypeRSA() {
        let key = "-----BEGIN RSA PRIVATE KEY-----\ndata\n-----END RSA PRIVATE KEY-----"
        XCTAssertEqual(SSHKeyParser.keyType(Data(key.utf8)), "rsa")
    }

    func testKeyTypeECDSA() {
        let key = "-----BEGIN EC PRIVATE KEY-----\ndata\n-----END EC PRIVATE KEY-----"
        XCTAssertEqual(SSHKeyParser.keyType(Data(key.utf8)), "ecdsa")
    }

    func testKeyTypeOpenSSH() {
        let key = "-----BEGIN OPENSSH PRIVATE KEY-----\ndata\n-----END OPENSSH PRIVATE KEY-----"
        XCTAssertEqual(SSHKeyParser.keyType(Data(key.utf8)), "openssh")
    }

    func testKeyTypePKCS8() {
        let key = "-----BEGIN PRIVATE KEY-----\ndata\n-----END PRIVATE KEY-----"
        XCTAssertEqual(SSHKeyParser.keyType(Data(key.utf8)), "pkcs8")
    }

    func testKeyTypeUnknown() {
        let key = "not a key"
        XCTAssertNil(SSHKeyParser.keyType(Data(key.utf8)))
    }

    func testKeyTypeEmptyData() {
        XCTAssertNil(SSHKeyParser.keyType(Data()))
    }
}
