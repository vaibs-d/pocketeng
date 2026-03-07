import SwiftUI

struct MarkdownContentView: View {
    let content: String
    let role: MessageRole

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    renderText(text)
                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                case .heading(let level, let text):
                    renderHeading(level: level, text: text)
                case .listItem(let text, let ordered, let index):
                    renderListItem(text: text, ordered: ordered, index: index)
                }
            }
        }
    }

    // MARK: - Block Types

    private enum Block {
        case text(String)
        case codeBlock(String?, String)
        case heading(Int, String)
        case listItem(String, Bool, Int)
    }

    // MARK: - Parser

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        let lines = content.components(separatedBy: "\n")
        var i = 0
        var textBuffer = ""
        var listIndex = 0

        while i < lines.count {
            let line = lines[i]

            // Code block
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                // Flush text buffer
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

            // Heading
            } else if line.hasPrefix("#") {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                let level = line.prefix(while: { $0 == "#" }).count
                let text = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(min(level, 4), text))
                listIndex = 0

            // Unordered list
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

            // Ordered list
            } else if let match = line.trimmingCharacters(in: .whitespaces)
                        .range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !textBuffer.isEmpty {
                    blocks.append(.text(textBuffer.trimmingCharacters(in: .newlines)))
                    textBuffer = ""
                }
                listIndex += 1
                let text = String(line.trimmingCharacters(in: .whitespaces)[match.upperBound...])
                blocks.append(.listItem(text, true, listIndex))

            // Regular text
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

    // MARK: - Renderers

    private func renderText(_ text: String) -> some View {
        Group {
            if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed)
                    .font(.system(.subheadline))
                    .foregroundColor(.textPrimary)
                    .tint(.accent)
            } else {
                Text(text)
                    .font(.system(.subheadline))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private func renderHeading(level: Int, text: String) -> some View {
        Text(text)
            .font(.system(
                level == 1 ? .title3 :
                level == 2 ? .headline :
                .subheadline,
                design: .default,
                weight: .semibold
            ))
            .foregroundColor(.textPrimary)
            .padding(.top, level == 1 ? 8 : 4)
    }

    private func renderListItem(text: String, ordered: Bool, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if ordered {
                Text("\(index).")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.textSecondary)
                    .frame(width: 20, alignment: .trailing)
            } else {
                Text("•")
                    .font(.system(.subheadline))
                    .foregroundColor(.accent)
                    .frame(width: 14, alignment: .center)
            }

            if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed)
                    .font(.system(.subheadline))
                    .foregroundColor(.textPrimary)
                    .tint(.accent)
            } else {
                Text(text)
                    .font(.system(.subheadline))
                    .foregroundColor(.textPrimary)
            }
        }
        .padding(.leading, 4)
    }
}

// MARK: - Code Block

struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var isExpanded = false

    private var lineCount: Int {
        code.components(separatedBy: "\n").count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.textTertiary)

                    if let lang = language, !lang.isEmpty {
                        Text(lang)
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.accent)
                    }

                    Text("\(lineCount) lines")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)

                    Spacer()

                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = code
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.surfaceBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Code content — expandable
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.textSecondary)
                        .padding(10)
                }
                .frame(maxHeight: 300)
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.surfaceBorder, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
