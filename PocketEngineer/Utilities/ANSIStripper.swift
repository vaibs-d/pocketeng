import Foundation

struct ANSIStripper {
    private static let ansiPattern = try! NSRegularExpression(
        pattern: "\\x1B\\[[0-9;]*[A-Za-z]|\\x1B\\].*?\\x07|\\x1B\\([A-Za-z]",
        options: []
    )

    static func strip(_ input: String) -> String {
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        return ansiPattern.stringByReplacingMatches(
            in: input,
            options: [],
            range: range,
            withTemplate: ""
        )
    }
}
