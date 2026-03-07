import XCTest
@testable import PocketEngineer

final class ClaudeOutputParserTests: XCTestCase {
    let parser = ClaudeOutputParser()

    // MARK: - System Init

    func testParseSystemInit() {
        let line = """
        {"type":"system","subtype":"init","cwd":"/home/ec2-user","session_id":"4e998062-ac68-4007-8adb-80e9b49eb5b7","tools":["Bash","Read"],"model":"claude-sonnet-4-6"}
        """
        let event = parser.parseLine(line)
        if case .initialized(let sessionId) = event {
            XCTAssertEqual(sessionId, "4e998062-ac68-4007-8adb-80e9b49eb5b7")
        } else {
            XCTFail("Expected initialized event, got \(String(describing: event))")
        }
    }

    func testParseSystemInitWithoutSessionId() {
        let line = """
        {"type":"system","subtype":"init","cwd":"/home/ec2-user"}
        """
        let event = parser.parseLine(line)
        XCTAssertNil(event, "System event without session_id should return nil")
    }

    // MARK: - Assistant Text

    func testParseAssistantWithNestedMessage() {
        let line = """
        {"type":"assistant","message":{"model":"claude-sonnet-4-6","id":"msg_01","type":"message","role":"assistant","content":[{"type":"text","text":"Hello!"}],"stop_reason":null},"session_id":"abc-123"}
        """
        let event = parser.parseLine(line)
        if case .assistantText(let text) = event {
            XCTAssertEqual(text, "Hello!")
        } else {
            XCTFail("Expected assistantText event, got \(String(describing: event))")
        }
    }

    func testParseAssistantMultipleTextBlocks() {
        let line = """
        {"type":"assistant","message":{"content":[{"type":"text","text":"Part 1"},{"type":"text","text":" Part 2"}]}}
        """
        let event = parser.parseLine(line)
        if case .assistantText(let text) = event {
            XCTAssertEqual(text, "Part 1 Part 2")
        } else {
            XCTFail("Expected assistantText event, got \(String(describing: event))")
        }
    }

    func testParseAssistantEmptyContent() {
        let line = """
        {"type":"assistant","message":{"content":[]}}
        """
        let event = parser.parseLine(line)
        XCTAssertNil(event, "Empty content array should return nil")
    }

    func testParseAssistantSimpleMessageString() {
        let line = """
        {"type":"assistant","message":"Simple text response"}
        """
        let event = parser.parseLine(line)
        if case .assistantText(let text) = event {
            XCTAssertEqual(text, "Simple text response")
        } else {
            XCTFail("Expected assistantText from simple message string")
        }
    }

    func testParseContentBlockDelta() {
        let line = """
        {"type":"content_block_delta","delta":{"type":"text_delta","text":"streaming chunk"}}
        """
        let event = parser.parseLine(line)
        if case .assistantText(let text) = event {
            XCTAssertEqual(text, "streaming chunk")
        } else {
            XCTFail("Expected assistantText from content_block_delta")
        }
    }

    func testParseContentBlockDeltaNonText() {
        let line = """
        {"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"..."}}
        """
        let event = parser.parseLine(line)
        XCTAssertNil(event, "Non-text delta should return nil")
    }

    // MARK: - Tool Use

    func testParseToolUseTopLevel() {
        let line = """
        {"type":"tool_use","name":"Bash","input":{"command":"ls -la"}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Bash")
            XCTAssertEqual(input, "ls -la")
        } else {
            XCTFail("Expected toolUse event, got \(String(describing: event))")
        }
    }

    func testParseToolUseWithToolWrapper() {
        let line = """
        {"type":"tool_use","tool":{"name":"Read","input":{"file_path":"/src/main.swift"}}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Read")
            XCTAssertEqual(input, "/src/main.swift")
        } else {
            XCTFail("Expected toolUse event, got \(String(describing: event))")
        }
    }

    func testParseToolUseEdit() {
        let line = """
        {"type":"tool_use","name":"Edit","input":{"file_path":"/src/main.swift","old_string":"func hello()","new_string":"func greet()"}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Edit")
            // file_path has higher priority than old_string in extractToolInput
            XCTAssertEqual(input, "/src/main.swift")
        } else {
            XCTFail("Expected toolUse event")
        }
    }

    func testParseToolUseEditWithoutFilePath() {
        let line = """
        {"type":"tool_use","name":"Edit","input":{"old_string":"func hello()","new_string":"func greet()"}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Edit")
            XCTAssertTrue(input.hasPrefix("edit: "))
        } else {
            XCTFail("Expected toolUse event")
        }
    }

    func testParseToolUseGlob() {
        let line = """
        {"type":"tool_use","name":"Glob","input":{"pattern":"**/*.swift"}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Glob")
            XCTAssertEqual(input, "**/*.swift")
        } else {
            XCTFail("Expected toolUse event")
        }
    }

    func testParseToolUseNoInput() {
        let line = """
        {"type":"tool_use","name":"Bash"}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Bash")
            XCTAssertEqual(input, "")
        } else {
            XCTFail("Expected toolUse event")
        }
    }

    func testParseToolUseFromAssistantContentBlock() {
        let line = """
        {"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"/app.py","content":"print('hi')"}}]}}
        """
        let event = parser.parseLine(line)
        if case .toolUse(let name, let input) = event {
            XCTAssertEqual(name, "Write")
            // file_path has higher priority than content in extractToolInput
            XCTAssertEqual(input, "/app.py")
        } else {
            XCTFail("Expected toolUse from assistant content block")
        }
    }

    // MARK: - Tool Result

    func testParseToolResult() {
        let line = """
        {"type":"tool_result","content":"total 48\\ndrwxr-xr-x  12 user  staff  384 Jan  1 12:00 ."}
        """
        let event = parser.parseLine(line)
        if case .toolResult(let output) = event {
            XCTAssertTrue(output.contains("total 48"))
        } else {
            XCTFail("Expected toolResult event, got \(String(describing: event))")
        }
    }

    func testParseToolResultWithOutputKey() {
        let line = """
        {"type":"tool_result","output":"file contents here"}
        """
        let event = parser.parseLine(line)
        if case .toolResult(let output) = event {
            XCTAssertEqual(output, "file contents here")
        } else {
            XCTFail("Expected toolResult event")
        }
    }

    func testParseToolResultContentArray() {
        let line = """
        {"type":"tool_result","content":[{"type":"text","text":"line 1"},{"type":"text","text":"line 2"}]}
        """
        let event = parser.parseLine(line)
        if case .toolResult(let output) = event {
            XCTAssertTrue(output.contains("line 1"))
            XCTAssertTrue(output.contains("line 2"))
        } else {
            XCTFail("Expected toolResult event")
        }
    }

    func testTruncatesLongToolResult() {
        let longOutput = String(repeating: "x", count: 1000)
        let line = """
        {"type":"tool_result","content":"\(longOutput)"}
        """
        let event = parser.parseLine(line)
        if case .toolResult(let output) = event {
            XCTAssertEqual(output.count, 500)
        } else {
            XCTFail("Expected toolResult event")
        }
    }

    func testParseToolResultEmpty() {
        let line = """
        {"type":"tool_result"}
        """
        let event = parser.parseLine(line)
        if case .toolResult(let output) = event {
            XCTAssertEqual(output, "")
        } else {
            XCTFail("Expected toolResult event with empty output")
        }
    }

    // MARK: - Result (Completion)

    func testParseResultSuccess() {
        let line = """
        {"type":"result","subtype":"success","is_error":false,"duration_ms":1612,"result":"Hello!","session_id":"abc-123","total_cost_usd":0.04}
        """
        let event = parser.parseLine(line)
        if case .completed(let status, let durationMs) = event {
            XCTAssertEqual(status, "success")
            XCTAssertEqual(durationMs, 1612)
        } else {
            XCTFail("Expected completed event, got \(String(describing: event))")
        }
    }

    func testParseResultError() {
        let line = """
        {"type":"result","subtype":"error","is_error":true,"result":"API key invalid","session_id":"abc-123"}
        """
        let event = parser.parseLine(line)
        if case .error(let msg) = event {
            XCTAssertEqual(msg, "API key invalid")
        } else {
            XCTFail("Expected error event, got \(String(describing: event))")
        }
    }

    func testParseResultNoDuration() {
        let line = """
        {"type":"result","subtype":"success","is_error":false}
        """
        let event = parser.parseLine(line)
        if case .completed(let status, let durationMs) = event {
            XCTAssertEqual(status, "success")
            XCTAssertNil(durationMs)
        } else {
            XCTFail("Expected completed event")
        }
    }

    // MARK: - Edge Cases

    func testParseInvalidJSON() {
        let event = parser.parseLine("this is not json")
        XCTAssertNil(event)
    }

    func testParseEmptyLine() {
        let event = parser.parseLine("")
        XCTAssertNil(event)
    }

    func testParseWhitespaceOnly() {
        let event = parser.parseLine("   \t  \n  ")
        XCTAssertNil(event)
    }

    func testParseUnknownType() {
        let line = """
        {"type":"unknown_event","data":"something"}
        """
        let event = parser.parseLine(line)
        XCTAssertNil(event)
    }

    func testParseWithANSICodes() {
        let line = "\u{1B}[32m{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"test-123\"}\u{1B}[0m"
        let event = parser.parseLine(line)
        if case .initialized(let sessionId) = event {
            XCTAssertEqual(sessionId, "test-123")
        } else {
            XCTFail("Should parse JSON even with ANSI codes wrapped around it")
        }
    }

    func testParseWithLeadingWhitespace() {
        let line = "   {\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"ws-test\"}"
        let event = parser.parseLine(line)
        if case .initialized(let sessionId) = event {
            XCTAssertEqual(sessionId, "ws-test")
        } else {
            XCTFail("Should handle leading whitespace")
        }
    }
}
