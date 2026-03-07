import Foundation

enum ClaudeEvent: Sendable {
    case initialized(sessionId: String)
    case assistantText(String)
    case toolUse(name: String, input: String)
    case toolResult(output: String)
    case completed(status: String, durationMs: Int?)
    case error(String)
}

struct ClaudeOutputParser {
    /// Parse a single line of NDJSON from Claude Code's --output-format stream-json --verbose
    ///
    /// Actual format from Claude Code v2.1.52:
    /// - {"type":"system","subtype":"init","session_id":"...","tools":[...],...}
    /// - {"type":"assistant","message":{"content":[{"type":"text","text":"..."}],...},"session_id":"..."}
    /// - {"type":"tool_use","tool":{"name":"Bash","input":{"command":"ls"}},"session_id":"..."}
    /// - {"type":"tool_result","content":"output...","session_id":"..."}
    /// - {"type":"result","subtype":"success","result":"final text","duration_ms":1234,"session_id":"..."}
    func parseLine(_ line: String) -> ClaudeEvent? {
        let stripped = ANSIStripper.strip(line).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !stripped.isEmpty else { return nil }

        guard let data = stripped.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
            return nil
        }

        switch type {
        case "system":
            return parseSystemEvent(json)

        case "assistant":
            return parseAssistantEvent(json)

        case "tool_use":
            return parseToolUseEvent(json)

        case "tool_result":
            return parseToolResultEvent(json)

        case "result":
            return parseResultEvent(json)

        case "content_block_delta":
            if let delta = json["delta"] as? [String: Any],
               delta["type"] as? String == "text_delta",
               let text = delta["text"] as? String {
                return .assistantText(text)
            }
            return nil

        default:
            return nil
        }
    }

    // MARK: - Event Parsers

    private func parseSystemEvent(_ json: [String: Any]) -> ClaudeEvent? {
        if let sessionId = json["session_id"] as? String {
            return .initialized(sessionId: sessionId)
        }
        return nil
    }

    private func parseAssistantEvent(_ json: [String: Any]) -> ClaudeEvent? {
        // Format: {"type":"assistant","message":{"content":[{"type":"text","text":"..."}]}}
        if let message = json["message"] as? [String: Any],
           let content = message["content"] as? [[String: Any]] {
            var textParts: [String] = []
            for block in content {
                if let blockType = block["type"] as? String {
                    switch blockType {
                    case "text":
                        if let text = block["text"] as? String {
                            textParts.append(text)
                        }
                    case "tool_use":
                        // Extract tool use from content blocks
                        let name = block["name"] as? String ?? "unknown"
                        let input = extractToolInput(block["input"] as? [String: Any])
                        return .toolUse(name: name, input: input)
                    default:
                        break
                    }
                }
            }
            let fullText = textParts.joined()
            if !fullText.isEmpty {
                return .assistantText(fullText)
            }
        }

        // Fallback: content at top level
        if let content = json["content"] as? [[String: Any]] {
            let texts = content.compactMap { block -> String? in
                guard block["type"] as? String == "text" else { return nil }
                return block["text"] as? String
            }
            let fullText = texts.joined()
            if !fullText.isEmpty {
                return .assistantText(fullText)
            }
        }

        // Fallback: simple message string
        if let message = json["message"] as? String, !message.isEmpty {
            return .assistantText(message)
        }

        return nil
    }

    private func parseToolUseEvent(_ json: [String: Any]) -> ClaudeEvent {
        // Format: {"type":"tool_use","tool":{"name":"Bash","input":{...}}}
        // or:     {"type":"tool_use","name":"Bash","input":{...}}
        let name: String
        let inputDict: [String: Any]?

        if let tool = json["tool"] as? [String: Any] {
            name = tool["name"] as? String ?? "unknown"
            inputDict = tool["input"] as? [String: Any]
        } else {
            name = json["name"] as? String ?? json["tool_name"] as? String ?? "unknown"
            inputDict = json["input"] as? [String: Any]
        }

        let input = extractToolInput(inputDict)
        return .toolUse(name: name, input: input)
    }

    private func parseToolResultEvent(_ json: [String: Any]) -> ClaudeEvent {
        let output: String
        if let content = json["content"] as? String {
            output = String(content.prefix(500))
        } else if let content = json["output"] as? String {
            output = String(content.prefix(500))
        } else if let contentArray = json["content"] as? [[String: Any]] {
            let texts = contentArray.compactMap { $0["text"] as? String }
            output = String(texts.joined(separator: "\n").prefix(500))
        } else {
            output = ""
        }
        return .toolResult(output: output)
    }

    private func parseResultEvent(_ json: [String: Any]) -> ClaudeEvent? {
        // Determine success/error
        let subtype = json["subtype"] as? String ?? "unknown"
        let isError = json["is_error"] as? Bool ?? false

        if isError {
            let errorMsg = json["result"] as? String ?? "Unknown error"
            return .error(errorMsg)
        }

        let durationMs = json["duration_ms"] as? Int ?? json["duration_api_ms"] as? Int

        // Don't emit the "result" text as assistantText — it duplicates
        // the text already received from the "assistant" event.
        // Just emit a completion event.
        return .completed(status: subtype, durationMs: durationMs)
    }

    // MARK: - Helpers

    private func extractToolInput(_ inputDict: [String: Any]?) -> String {
        guard let inputDict = inputDict else { return "" }

        if let command = inputDict["command"] as? String {
            return command
        } else if let filePath = inputDict["file_path"] as? String {
            return filePath
        } else if let pattern = inputDict["pattern"] as? String {
            return pattern
        } else if let prompt = inputDict["prompt"] as? String {
            return String(prompt.prefix(100))
        } else if let oldString = inputDict["old_string"] as? String {
            return "edit: \(String(oldString.prefix(80)))"
        } else if let content = inputDict["content"] as? String {
            return String(content.prefix(80))
        } else {
            if let jsonData = try? JSONSerialization.data(withJSONObject: inputDict, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return String(jsonString.prefix(200))
            }
            return String(describing: inputDict).prefix(200).description
        }
    }
}
