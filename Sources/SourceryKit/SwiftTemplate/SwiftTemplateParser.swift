import Foundation

open class SwiftTemplateParser {
    enum Delimiter {
        static let open = "<%"
        static let close = "%>"
    }

    private var parsedTemplates: [Path] = []

    func parse(file: Path) throws -> [SwiftTemplate.Command] {
        do {
            let template = try file.read(.utf8)
            parsedTemplates.append(file)
            let commands = try parse(template: template).flatMap { command -> [SwiftTemplate.Command] in
                guard case let .include(relativeIncludePath, line) = command else {
                    return [command]
                }
                let includePath = Path(components: [file.parent().string, relativeIncludePath.string])
                if parsedTemplates.contains(includePath) {
                    throw Error.includeCycle(file: file, line: line, includePath: relativeIncludePath)
                }
                if relativeIncludePath.isTemplateFile {
                    return try parse(file: includePath)
                }
                if relativeIncludePath.isSwiftSourceFile {
                    return [.include(includePath, line: line)]
                }
                return [command]
            }
            return commands
        } catch ParsingError.invalidIncludeStatement(let line) {
            throw Error.invalidIncludeStatement(file: file, line: line)
        } catch ParsingError.missingClosingTag(let line) {
            throw Error.missingClosingTag(file: file, line: line)
        }
    }

    func parse(template: String) throws -> [SwiftTemplate.Command] {
        let templateContent = "<%%>" + template

        let components = templateContent.components(separatedBy: Delimiter.open)

        var processedComponents: [String] = []
        var commands: [SwiftTemplate.Command] = []

        let currentLineNumber = {
            processedComponents.joined(separator: "").numberOfLineSeparators + 1
        }

        for component in components.suffix(from: 1) {
            guard let endIndex = component.range(of: Delimiter.close) else {
                throw ParsingError.missingClosingTag(line: currentLineNumber())
            }

            var code = String(component[..<endIndex.lowerBound])
            let shouldTrimTrailingNewLines = code.trimSuffix("-")
            let shouldTrimLeadingWhitespaces = code.trimPrefix("_")
            let shouldTrimTrailingWhitespaces = code.trimSuffix("_")

            // string after closing tag
            var encodedPart = String(component[endIndex.upperBound...])
            if shouldTrimTrailingNewLines {
                // we trim only new line caused by script tag, not all of leading new lines in string after tag
                encodedPart = encodedPart.replacingOccurrences(of: "^\\n{1}", with: "", options: .regularExpression, range: nil)
            }
            if shouldTrimTrailingWhitespaces {
                // trim all leading whitespaces in string after tag
                encodedPart = encodedPart.replacingOccurrences(of: "^[\\h\\t]*", with: "", options: .regularExpression, range: nil)
            }
            if shouldTrimLeadingWhitespaces {
                if case let .outputEncoded(code)? = commands.last {
                    // trim all trailing white spaces in previously enqued code string
                    let trimmed = code.replacingOccurrences(of: "[\\h\\t]*$", with: "", options: .regularExpression, range: nil)
                    _ = commands.popLast()
                    commands.append(.outputEncoded(trimmed))
                }
            }

            if code.trimPrefix("-") {
                let includeCommand = try parseIncludeCommand(from: code, inLine: currentLineNumber())
                commands.append(includeCommand)
            } else if code.trimPrefix("=") {
                commands.append(.output(code.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if !code.hasPrefix("#") {
                let statement = code.trimmingCharacters(in: .whitespacesAndNewlines)
                if statement.isNotEmpty {
                    commands.append(.controlFlow(statement))
                }
            }

            if encodedPart.isNotEmpty {
                commands.append(.outputEncoded(encodedPart))
            }
            processedComponents.append(component)
        }

        return commands
    }

    private func parseIncludeCommand(from code: String, inLine line: Int) throws -> SwiftTemplate.Command {
        guard let match = try /include\("(?<filePath>[^"]+)"\)/.firstMatch(in: code) else {
            throw ParsingError.invalidIncludeStatement(line: line)
        }
        let fileToInclude = "\(match.filePath)"
        if try /.+\..+/.wholeMatch(in: fileToInclude) == nil {
            throw ParsingError.missingFileExtension(line: line)
        }
        if fileToInclude.hasSuffix(".swift") || fileToInclude.hasSuffix(".swifttemplate") {
            return .include(Path(fileToInclude), line: line)
        }
        throw ParsingError.unsupportedFileExtension(line: line)
    }

    enum Error: Swift.Error, Equatable {
        case includeCycle(file: Path, line: Int, includePath: Path)
        case invalidIncludeStatement(file: Path, line: Int)
        case missingClosingTag(file: Path, line: Int)
        case missingFileExtension(file: Path, line: Int)
    }

    enum ParsingError: Swift.Error, Equatable {
        case invalidIncludeStatement(line: Int)
        case missingClosingTag(line: Int)
        case missingFileExtension(line: Int)
        case unsupportedFileExtension(line: Int)
    }
}

extension SwiftTemplateParser.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .includeCycle(file, line, includePath):
            "Include cycle detected for \(includePath.lastComponent) in \(file):\(line)"
        case let .invalidIncludeStatement(file, line):
            "Invalid include tag format in \(file):\(line)"
        case let .missingClosingTag(file, line):
            "Missing closing tag '%>' in \(file):\(line)"
        case let .missingFileExtension(file, line):
            "Missing file extension in include statement in \(file):\(line)"
        }
    }
}

// swiftlint:disable:next force_try
private let newlines = try! NSRegularExpression(pattern: "\\n\\r|\\r\\n|\\r|\\n", options: [])

private extension String {
    var numberOfLineSeparators: Int {
        newlines.matches(in: self, options: [], range: NSRange(location: 0, length: count)).count
    }
}
