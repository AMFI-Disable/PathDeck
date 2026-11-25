import Foundation

/// A thread-safe, line-preserving tokenizer engine for parsing and serializing shell configuration files.
public final class ShellConfigParser {

    // Thread safety lock
    private static let lock = NSLock()

    // Regular Expressions with capture groups for optional inline trailing comments.
    // Top-level PATH exports omit leading indentation so scoped exports inside `if` or function blocks stay `.raw`.
    private static let pathPrependRegex = try! NSRegularExpression(
        pattern: #"^export\s+PATH=(["']?)([^"':#]*?):\$PATH\1\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let pathAppendRegex = try! NSRegularExpression(
        pattern: #"^export\s+PATH=(["']?)\$PATH:([^"':#]*?)\1\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let disabledPathPrependRegex = try! NSRegularExpression(
        pattern: #"^#\s*export\s+PATH=(["']?)([^"':#]*?):\$PATH\1\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let disabledPathAppendRegex = try! NSRegularExpression(
        pattern: #"^#\s*export\s+PATH=(["']?)\$PATH:([^"':#]*?)\1\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let aliasRegex = try! NSRegularExpression(
        pattern: #"^\s*alias\s+([a-zA-Z0-9_\.\-]+)=([\"'])(.*?)\2\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let disabledAliasRegex = try! NSRegularExpression(
        pattern: #"^\s*#\s*alias\s+([a-zA-Z0-9_\.\-]+)=([\"'])(.*?)\2\s*(?:#\s*(.*))?$"#,
        options: []
    )

    private static let envVarRegex = try! NSRegularExpression(
        pattern: #"^\s*export\s+([a-zA-Z_][a-zA-Z0-9_]*)=([\"'])(.*?)\2\s*(?:#\s*(.*))?$"#,
        options: []
    )

    /// Validates a shell environment variable identifier.
    public static func isValidEnvVarKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let first = trimmed.first else { return false }
        guard first.isLetter || first == "_" else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Validates a shell alias name.
    public static func isValidAliasName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." || $0 == "-" }
    }

    private static func escapeDoubleQuoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Parses a shell configuration string line-by-line into structured AST `ConfigLine` elements.
    /// - Parameter string: The raw configuration file contents.
    /// - Returns: An array of tokenized `ConfigLine` structures.
    public static func parse(contentsOf string: String) -> [ConfigLine] {
        lock.lock()
        defer { lock.unlock() }

        let rawLines = string.components(separatedBy: .newlines)
        var parsedLines = [ConfigLine]()

        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 1. Match Empty Line
            if trimmed.isEmpty {
                parsedLines.append(.empty)
                continue
            }

            let nsString = line as NSString
            let range = NSRange(location: 0, length: nsString.length)

            // 2. Match Commented-Out Alias (# alias gs="git status") so deactivated
            //    shortcuts survive save/load round-trips instead of collapsing into comments
            if let match = disabledAliasRegex.firstMatch(in: line, options: [], range: range) {
                let nameVal = nsString.substring(with: match.range(at: 1))
                let cmdVal = nsString.substring(with: match.range(at: 3))
                let commentVal = match.range(at: 4).location != NSNotFound ? nsString.substring(with: match.range(at: 4)) : nil
                parsedLines.append(.alias(name: nameVal, value: cmdVal, isEnabled: false, comment: commentVal))
                continue
            }

            // 2b. Match Commented-Out PATH Prepend/Append (# export PATH="/dir:$PATH")
            if let match = disabledPathPrependRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.disabledPathExport(path: pathVal, isPrepend: true, comment: commentVal))
                continue
            }
            if let match = disabledPathAppendRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.disabledPathExport(path: pathVal, isPrepend: false, comment: commentVal))
                continue
            }

            // 3. Match Pure Comment (Starts with #)
            if trimmed.hasPrefix("#") {
                parsedLines.append(.comment(text: line))
                continue
            }

            // 4. Match PATH Prepend (export PATH="/dir:$PATH")
            if let match = pathPrependRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.pathExport(path: pathVal, isPrepend: true, comment: commentVal))
                continue
            }

            // 5. Match PATH Append (export PATH="$PATH:/dir")
            if let match = pathAppendRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.pathExport(path: pathVal, isPrepend: false, comment: commentVal))
                continue
            }

            // 6. Match Alias (alias name="value")
            if let match = aliasRegex.firstMatch(in: line, options: [], range: range) {
                let nameVal = nsString.substring(with: match.range(at: 1))
                let cmdVal = nsString.substring(with: match.range(at: 3))
                let commentVal = match.range(at: 4).location != NSNotFound ? nsString.substring(with: match.range(at: 4)) : nil
                parsedLines.append(.alias(name: nameVal, value: cmdVal, isEnabled: true, comment: commentVal))
                continue
            }

            // 7. Match Environment Variables (export NAME="value"), excluding indented/complex PATH exports
            if let match = envVarRegex.firstMatch(in: line, options: [], range: range) {
                let keyVal = nsString.substring(with: match.range(at: 1))
                if keyVal != "PATH" {
                    let valVal = nsString.substring(with: match.range(at: 3))
                    let commentVal = match.range(at: 4).location != NSNotFound ? nsString.substring(with: match.range(at: 4)) : nil

                    let uppercaseKey = keyVal.uppercased()
                    let sensitiveKeywords = ["KEY", "TOKEN", "PASSWORD", "SECRET", "AUTH", "PASS"]
                    let isSensitive = sensitiveKeywords.contains { uppercaseKey.contains($0) }

                    parsedLines.append(.envVar(name: keyVal, value: valVal, isSensitive: isSensitive, comment: commentVal))
                    continue
                }
            }

            // 8. Safety Fallback: treat as raw line to preserve loops, conditionals, or custom commands
            parsedLines.append(.raw(content: line))
        }

        return parsedLines
    }

    /// Re-serializes a list of structured `ConfigLine` tokens back into a single shell profile string.
    /// Consolidated PATH block overrides duplicate loose paths and replaces the first PATH export position.
    /// - Parameter lines: The token list to serialize.
    /// - Returns: A round-trip formatted configuration text.
    public static func serialize(_ lines: [ConfigLine]) -> String {
        lock.lock()
        defer { lock.unlock() }

        // 1. Extract all PATH exports to bundle them cleanly
        var pathExports = [ConfigLine]()
        for line in lines {
            switch line {
            case .pathExport, .disabledPathExport:
                pathExports.append(line)
            default:
                break
            }
        }

        // 2. Find the index of the first PATH export line to insert our consolidated block
        var firstPathExportIndex: Int?
        for (index, line) in lines.enumerated() {
            switch line {
            case .pathExport, .disabledPathExport:
                firstPathExportIndex = index
            default:
                continue
            }
            break
        }

        var serializedLines = [String]()

        // Helper to output the consolidated PATH stack block
        let appendPathBlock = {
            if !pathExports.isEmpty {
                serializedLines.append("# >>> PathDeck PATH Section >>>")
                for pathLine in pathExports {
                    switch pathLine {
                    case .pathExport(let path, let isPrepend, let comment):
                        let commentSuffix = comment != nil ? " # \(comment!)" : ""
                        if isPrepend {
                            serializedLines.append("export PATH=\"\(path):$PATH\"\(commentSuffix)")
                        } else {
                            serializedLines.append("export PATH=\"$PATH:\(path)\"\(commentSuffix)")
                        }
                    case .disabledPathExport(let path, let isPrepend, let comment):
                        let commentSuffix = comment != nil ? " # \(comment!)" : ""
                        if isPrepend {
                            serializedLines.append("# export PATH=\"\(path):$PATH\"\(commentSuffix)")
                        } else {
                            serializedLines.append("# export PATH=\"$PATH:\(path)\"\(commentSuffix)")
                        }
                    default:
                        break
                    }
                }
                serializedLines.append("# <<< PathDeck PATH Section <<<")
            }
        }

        var pathBlockInserted = false

        for (index, line) in lines.enumerated() {
            switch line {
            case .pathExport, .disabledPathExport:
                // Replace the first PATH export with the consolidated block, and skip subsequent ones
                if !pathBlockInserted {
                    if let firstIdx = firstPathExportIndex, index == firstIdx {
                        appendPathBlock()
                        pathBlockInserted = true
                    }
                }

            case .alias(let name, let value, let isEnabled, let comment):
                let commentSuffix = comment != nil ? " # \(comment!)" : ""
                let safeValue = escapeDoubleQuoted(value)
                if isEnabled {
                    serializedLines.append("alias \(name)=\"\(safeValue)\"\(commentSuffix)")
                } else {
                    serializedLines.append("# alias \(name)=\"\(safeValue)\"\(commentSuffix)")
                }

            case .envVar(let name, let value, _, let comment):
                let commentSuffix = comment != nil ? " # \(comment!)" : ""
                let safeValue = escapeDoubleQuoted(value)
                serializedLines.append("export \(name)=\"\(safeValue)\"\(commentSuffix)")

            case .comment(let text):
                // Filter out any pre-existing PathDeck marker comments to avoid duplicates
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if trimmed == "# >>> PathDeck PATH Section >>>" || trimmed == "# <<< PathDeck PATH Section <<<" {
                    continue
                }
                serializedLines.append(text)

            case .empty:
                serializedLines.append("")

            case .raw(let content):
                serializedLines.append(content)
            }
        }

        // If there were no PATH exports in the original file, append the consolidated block at the end
        if !pathBlockInserted && !pathExports.isEmpty {
            serializedLines.append("")
            appendPathBlock()
        }

        return serializedLines.joined(separator: "\n")
    }
}
