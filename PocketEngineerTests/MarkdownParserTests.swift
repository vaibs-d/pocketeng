import XCTest
@testable import PocketEngineer

/// Tests for the markdown block parser logic in MarkdownContentView.
/// We extract and test the parsing logic by using a test-accessible parser.
final class MarkdownParserTests: XCTestCase {

    // We test the parsing indirectly through a helper that mimics the same logic.
    // This validates the core parsing algorithm used in MarkdownContentView.

    // MARK: - Block Types

    enum TestBlock: Equatable {
        case text(String)
        case codeBlock(String?, String)
        case heading(Int, String)
        case listItem(String, Bool, Int) // text, ordered, index
    }

    /// Mirror of MarkdownContentView.parseBlocks()
    private func parseBlocks(_ content: String) -> [TestBlock] {
        var blocks: [TestBlock] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        var textBuffer = ""
        var listIndex = 0

        while i < lines.count {
            let line = lines[i]

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                let lang = line.trimmingCharacters(in: .whitespaces)
                    .dropFirst(3)
                    .trimmingCharacters(in: .whitespaces)
                let language = lang.isEmpty ? nil : lang

                var codeLines: [String] = []
                i += 1
                while i < lines.count {
                    let codeLine = lines[i]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        break
                    }
                    codeLines.append(codeLine)
                    i += 1
                }
                blocks.append(.codeBlock(language, codeLines.joined(separator: "\n")))
                listIndex = 0

            } else if line.hasPrefix("#") {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                let level = line.prefix(while: { $0 == "#" }).count
                let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(min(level, 4), text))
                listIndex = 0

            } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("- ") ||
                      line.trimmingCharacters(in: .whitespaces).hasPrefix("* ") {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                let text = line.trimmingCharacters(in: .whitespaces)
                    .dropFirst(2)
                    .trimmingCharacters(in: .whitespaces)
                blocks.append(.listItem(String(text), false, 0))

            } else if let match = line.trimmingCharacters(in: .whitespaces)
                        .range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                listIndex += 1
                let text = String(line.trimmingCharacters(in: .whitespaces)[match.upperBound...])
                blocks.append(.listItem(text, true, listIndex))

            } else {
                if !line.isEmpty || !textBuffer.isEmpty {
                    textBuffer += (textBuffer.isEmpty ? "" : "\n") + line
                }
                if line.isEmpty { listIndex = 0 }
            }

            i += 1
        }

        if !textBuffer.isEmpty {
            blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
        }

        return blocks
    }

    // MARK: - Plain Text

    func testPlainText() {
        let blocks = parseBlocks("Hello world")
        XCTAssertEqual(blocks, [.text("Hello world")])
    }

    func testMultiLineText() {
        let blocks = parseBlocks("Line 1\nLine 2\nLine 3")
        XCTAssertEqual(blocks, [.text("Line 1\nLine 2\nLine 3")])
    }

    func testEmptyString() {
        let blocks = parseBlocks("")
        XCTAssertTrue(blocks.isEmpty)
    }

    // MARK: - Headings

    func testH1() {
        let blocks = parseBlocks("# Title")
        XCTAssertEqual(blocks, [.heading(1, "Title")])
    }

    func testH2() {
        let blocks = parseBlocks("## Subtitle")
        XCTAssertEqual(blocks, [.heading(2, "Subtitle")])
    }

    func testH3() {
        let blocks = parseBlocks("### Section")
        XCTAssertEqual(blocks, [.heading(3, "Section")])
    }

    func testH4() {
        let blocks = parseBlocks("#### Subsection")
        XCTAssertEqual(blocks, [.heading(4, "Subsection")])
    }

    func testH5CapsAt4() {
        let blocks = parseBlocks("##### Deep")
        XCTAssertEqual(blocks, [.heading(4, "Deep")], "Heading levels > 4 should cap at 4")
    }

    func testHeadingWithTextBefore() {
        let blocks = parseBlocks("Some text\n# Title")
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[0], .text("Some text"))
        XCTAssertEqual(blocks[1], .heading(1, "Title"))
    }

    // MARK: - Code Blocks

    func testCodeBlock() {
        let content = "```python\nprint('hello')\n```"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks, [.codeBlock("python", "print('hello')")])
    }

    func testCodeBlockNoLanguage() {
        let content = "```\nsome code\n```"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks, [.codeBlock(nil, "some code")])
    }

    func testCodeBlockMultipleLines() {
        let content = "```swift\nlet x = 1\nlet y = 2\nprint(x + y)\n```"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks, [.codeBlock("swift", "let x = 1\nlet y = 2\nprint(x + y)")])
    }

    func testCodeBlockWithTextAround() {
        let content = "Before\n```js\nconsole.log('hi')\n```\nAfter"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0], .text("Before"))
        XCTAssertEqual(blocks[1], .codeBlock("js", "console.log('hi')"))
        XCTAssertEqual(blocks[2], .text("After"))
    }

    func testMultipleCodeBlocks() {
        let content = "```py\na=1\n```\nText\n```bash\nls\n```"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0], .codeBlock("py", "a=1"))
        XCTAssertEqual(blocks[1], .text("Text"))
        XCTAssertEqual(blocks[2], .codeBlock("bash", "ls"))
    }

    func testUnclosedCodeBlock() {
        // If code block is never closed, collect until end
        let content = "```python\nprint('hi')\nmore code"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks, [.codeBlock("python", "print('hi')\nmore code")])
    }

    // MARK: - Unordered Lists

    func testUnorderedListDash() {
        let content = "- Item 1\n- Item 2\n- Item 3"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0], .listItem("Item 1", false, 0))
        XCTAssertEqual(blocks[1], .listItem("Item 2", false, 0))
        XCTAssertEqual(blocks[2], .listItem("Item 3", false, 0))
    }

    func testUnorderedListAsterisk() {
        let content = "* First\n* Second"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[0], .listItem("First", false, 0))
        XCTAssertEqual(blocks[1], .listItem("Second", false, 0))
    }

    // MARK: - Ordered Lists

    func testOrderedList() {
        let content = "1. First\n2. Second\n3. Third"
        let blocks = parseBlocks(content)
        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0], .listItem("First", true, 1))
        XCTAssertEqual(blocks[1], .listItem("Second", true, 2))
        XCTAssertEqual(blocks[2], .listItem("Third", true, 3))
    }

    func testOrderedListResets() {
        // Empty line between lists should reset index
        let content = "1. A\n2. B\n\n1. C\n2. D"
        let blocks = parseBlocks(content)
        // After empty line, listIndex resets to 0, then increments
        let orderedItems = blocks.compactMap { block -> (String, Int)? in
            if case .listItem(let text, true, let idx) = block { return (text, idx) }
            return nil
        }
        XCTAssertEqual(orderedItems.count, 4)
        XCTAssertEqual(orderedItems[0].1, 1) // A = index 1
        XCTAssertEqual(orderedItems[1].1, 2) // B = index 2
        XCTAssertEqual(orderedItems[2].1, 1) // C = index 1 (reset)
        XCTAssertEqual(orderedItems[3].1, 2) // D = index 2
    }

    // MARK: - Mixed Content

    func testMixedContent() {
        let content = """
        # Getting Started
        Here's how to begin:
        1. Install dependencies
        2. Run the server
        ```bash
        npm start
        ```
        - Check the logs
        - Verify output
        Done!
        """
        let blocks = parseBlocks(content)

        XCTAssertTrue(blocks.count >= 7, "Should have heading + text + 2 ordered + code + 2 unordered + text")

        // First block should be heading
        if case .heading(1, let text) = blocks[0] {
            XCTAssertEqual(text, "Getting Started")
        } else {
            XCTFail("First block should be h1")
        }

        // Should contain a code block
        let hasCodeBlock = blocks.contains { block in
            if case .codeBlock("bash", "npm start") = block { return true }
            return false
        }
        XCTAssertTrue(hasCodeBlock, "Should contain bash code block")
    }

    // MARK: - Realistic Claude Output

    func testClaudeResponseWithCode() {
        let content = """
        I've created the file. Here's what it does:

        ```python
        from flask import Flask
        app = Flask(__name__)

        @app.route('/')
        def hello():
            return 'Hello World!'
        ```

        The server will run on port 5000 by default.
        """
        let blocks = parseBlocks(content)

        // Should have: text, code block, text
        let codeBlocks = blocks.filter { if case .codeBlock = $0 { return true }; return false }
        XCTAssertEqual(codeBlocks.count, 1)

        if case .codeBlock(let lang, let code) = codeBlocks[0] {
            XCTAssertEqual(lang, "python")
            XCTAssertTrue(code.contains("Flask"))
            XCTAssertTrue(code.contains("hello"))
        }
    }
}
