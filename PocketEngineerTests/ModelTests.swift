import XCTest
@testable import PocketEngineer

// MARK: - SessionStatus Tests

final class SessionStatusTests: XCTestCase {

    func testAllStatusRawValues() {
        XCTAssertEqual(SessionStatus.active.rawValue, "active")
        XCTAssertEqual(SessionStatus.idle.rawValue, "idle")
        XCTAssertEqual(SessionStatus.completed.rawValue, "completed")
        XCTAssertEqual(SessionStatus.error.rawValue, "error")
    }

    func testStatusFromRawValue() {
        XCTAssertEqual(SessionStatus(rawValue: "active"), .active)
        XCTAssertEqual(SessionStatus(rawValue: "idle"), .idle)
        XCTAssertEqual(SessionStatus(rawValue: "completed"), .completed)
        XCTAssertEqual(SessionStatus(rawValue: "error"), .error)
        XCTAssertNil(SessionStatus(rawValue: "invalid"))
    }
}

// MARK: - MessageRole Tests

final class MessageRoleTests: XCTestCase {

    func testAllRoleRawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    func testRoleFromRawValue() {
        XCTAssertEqual(MessageRole(rawValue: "user"), .user)
        XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
        XCTAssertEqual(MessageRole(rawValue: "system"), .system)
        XCTAssertNil(MessageRole(rawValue: "invalid"))
    }
}

// MARK: - MessageState Tests

final class MessageStateTests: XCTestCase {

    func testAllStateRawValues() {
        XCTAssertEqual(MessageState.complete.rawValue, "complete")
        XCTAssertEqual(MessageState.streaming.rawValue, "streaming")
        XCTAssertEqual(MessageState.error.rawValue, "error")
    }

    func testStateFromRawValue() {
        XCTAssertEqual(MessageState(rawValue: "complete"), .complete)
        XCTAssertEqual(MessageState(rawValue: "streaming"), .streaming)
        XCTAssertEqual(MessageState(rawValue: "error"), .error)
        XCTAssertNil(MessageState(rawValue: "invalid"))
    }
}

// MARK: - ToolType Tests

final class ToolTypeTests: XCTestCase {

    func testAllToolTypeRawValues() {
        XCTAssertEqual(ToolType.bash.rawValue, "bash")
        XCTAssertEqual(ToolType.read.rawValue, "read")
        XCTAssertEqual(ToolType.edit.rawValue, "edit")
        XCTAssertEqual(ToolType.write.rawValue, "write")
        XCTAssertEqual(ToolType.glob.rawValue, "glob")
        XCTAssertEqual(ToolType.grep.rawValue, "grep")
        XCTAssertEqual(ToolType.task.rawValue, "task")
        XCTAssertEqual(ToolType.unknown.rawValue, "unknown")
    }

    func testToolTypeFromRawValue() {
        XCTAssertEqual(ToolType(rawValue: "bash"), .bash)
        XCTAssertEqual(ToolType(rawValue: "read"), .read)
        XCTAssertEqual(ToolType(rawValue: "edit"), .edit)
        XCTAssertEqual(ToolType(rawValue: "write"), .write)
        XCTAssertEqual(ToolType(rawValue: "glob"), .glob)
        XCTAssertEqual(ToolType(rawValue: "grep"), .grep)
        XCTAssertEqual(ToolType(rawValue: "task"), .task)
        XCTAssertEqual(ToolType(rawValue: "unknown"), .unknown)
        XCTAssertNil(ToolType(rawValue: "nonexistent"))
    }
}

// MARK: - ChatMessage Tests

final class ChatMessageTests: XCTestCase {

    func testUserMessageInit() {
        let msg = ChatMessage(role: .user, content: "Hello")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hello")
        XCTAssertEqual(msg.state, .complete)
        XCTAssertNotNil(msg.id)
        XCTAssertNotNil(msg.timestamp)
        XCTAssertTrue(msg.toolActivities.isEmpty)
    }

    func testAssistantMessageInit() {
        let msg = ChatMessage(role: .assistant, content: "Hi there!")
        XCTAssertEqual(msg.role, .assistant)
        XCTAssertEqual(msg.content, "Hi there!")
    }

    func testSystemMessageInit() {
        let msg = ChatMessage(role: .system, content: "Session started")
        XCTAssertEqual(msg.role, .system)
    }

    func testStreamingStateInit() {
        let msg = ChatMessage(role: .assistant, content: "", state: .streaming)
        XCTAssertEqual(msg.state, .streaming)
        XCTAssertTrue(msg.content.isEmpty)
    }

    func testErrorStateInit() {
        let msg = ChatMessage(role: .assistant, content: "Error occurred", state: .error)
        XCTAssertEqual(msg.state, .error)
    }

    func testRoleGetterWithInvalidRaw() {
        let msg = ChatMessage(role: .user, content: "test")
        msg.roleRaw = "invalid_role"
        XCTAssertEqual(msg.role, .system, "Invalid role should default to .system")
    }

    func testStateGetterWithInvalidRaw() {
        let msg = ChatMessage(role: .user, content: "test")
        msg.stateRaw = "invalid_state"
        XCTAssertEqual(msg.state, .complete, "Invalid state should default to .complete")
    }

    func testRoleSetter() {
        let msg = ChatMessage(role: .user, content: "test")
        msg.role = .assistant
        XCTAssertEqual(msg.roleRaw, "assistant")
        XCTAssertEqual(msg.role, .assistant)
    }

    func testStateSetter() {
        let msg = ChatMessage(role: .user, content: "test")
        msg.state = .error
        XCTAssertEqual(msg.stateRaw, "error")
        XCTAssertEqual(msg.state, .error)
    }

    func testUniqueIDs() {
        let msg1 = ChatMessage(role: .user, content: "a")
        let msg2 = ChatMessage(role: .user, content: "b")
        XCTAssertNotEqual(msg1.id, msg2.id, "Each message should have a unique ID")
    }
}

// MARK: - ToolActivity Tests

final class ToolActivityTests: XCTestCase {

    func testBashToolInit() {
        let activity = ToolActivity(toolName: "Bash", input: "ls -la")
        XCTAssertEqual(activity.toolName, "Bash")
        XCTAssertEqual(activity.input, "ls -la")
        XCTAssertNil(activity.output)
        XCTAssertNil(activity.durationMs)
        XCTAssertNotNil(activity.id)
        XCTAssertNotNil(activity.timestamp)
    }

    func testToolTypeMapping() {
        let bashActivity = ToolActivity(toolName: "bash", input: "ls")
        XCTAssertEqual(bashActivity.toolType, .bash)

        let readActivity = ToolActivity(toolName: "read", input: "/file")
        XCTAssertEqual(readActivity.toolType, .read)

        let editActivity = ToolActivity(toolName: "edit", input: "content")
        XCTAssertEqual(editActivity.toolType, .edit)

        let writeActivity = ToolActivity(toolName: "write", input: "content")
        XCTAssertEqual(writeActivity.toolType, .write)

        let globActivity = ToolActivity(toolName: "glob", input: "*.swift")
        XCTAssertEqual(globActivity.toolType, .glob)

        let grepActivity = ToolActivity(toolName: "grep", input: "pattern")
        XCTAssertEqual(grepActivity.toolType, .grep)
    }

    func testUnknownToolType() {
        let activity = ToolActivity(toolName: "CustomTool", input: "data")
        XCTAssertEqual(activity.toolType, .unknown)
    }

    func testCaseSensitiveToolName() {
        // ToolType mapping uses lowercased, so "Bash" -> "bash" -> .bash
        let activity = ToolActivity(toolName: "Bash", input: "cmd")
        XCTAssertEqual(activity.toolType, .bash)
    }

    func testToolTypeSetter() {
        let activity = ToolActivity(toolName: "test", input: "data")
        activity.toolType = .bash
        XCTAssertEqual(activity.toolTypeRaw, "bash")
    }

    func testOutputAssignment() {
        let activity = ToolActivity(toolName: "Bash", input: "echo hi")
        XCTAssertNil(activity.output)
        activity.output = "hi"
        XCTAssertEqual(activity.output, "hi")
    }

    func testDurationAssignment() {
        let activity = ToolActivity(toolName: "Bash", input: "sleep 1")
        XCTAssertNil(activity.durationMs)
        activity.durationMs = 1042
        XCTAssertEqual(activity.durationMs, 1042)
    }
}

// MARK: - Session Tests

final class SessionTests: XCTestCase {

    func testSessionInit() {
        let session = Session(title: "My Project")
        XCTAssertEqual(session.title, "My Project")
        XCTAssertEqual(session.status, .idle)
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertNil(session.remoteSessionId)
        XCTAssertNil(session.projectContext)
        XCTAssertNil(session.serverConfig)
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.createdAt)
        XCTAssertNotNil(session.updatedAt)
    }

    func testSessionStatusGetterSetter() {
        let session = Session(title: "Test")
        XCTAssertEqual(session.status, .idle)

        session.status = .active
        XCTAssertEqual(session.statusRaw, "active")
        XCTAssertEqual(session.status, .active)

        session.status = .error
        XCTAssertEqual(session.statusRaw, "error")
        XCTAssertEqual(session.status, .error)

        session.status = .completed
        XCTAssertEqual(session.status, .completed)
    }

    func testSessionStatusDefaultsToIdle() {
        let session = Session(title: "Test")
        session.statusRaw = "garbage_value"
        XCTAssertEqual(session.status, .idle, "Invalid statusRaw should default to .idle")
    }

    func testProjectContext() {
        let session = Session(title: "Test")
        XCTAssertNil(session.projectContext)

        session.projectContext = "Use React with TypeScript"
        XCTAssertEqual(session.projectContext, "Use React with TypeScript")

        session.projectContext = nil
        XCTAssertNil(session.projectContext)
    }

    func testUniqueSessionIDs() {
        let s1 = Session(title: "A")
        let s2 = Session(title: "B")
        XCTAssertNotEqual(s1.id, s2.id)
    }
}
