import Foundation
import SwiftSyntax

struct AnnotationParser {
    struct Line: Equatable {
        enum LineType {
            case comment
            case documentationComment
            case other
        }

        let content: String
        let type: LineType
        let annotations: Annotations
    }

    let argumentParser = AnnotationArgumentParser()

    func parse(_ content: String) -> [Line] {
        content.components(separatedBy: .newlines).map { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            let isComment = trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("/*") || trimmedLine.hasPrefix("*")
            let isDocumentationComment = trimmedLine.hasPrefix("///") || trimmedLine.hasPrefix("/**")

            var type = Line.LineType.other
            if isDocumentationComment {
                type = .documentationComment
            } else if isComment {
                type = .comment
            }

            let annotations = if isComment {
                searchForAnnotations(commentLine: trimmedLine)
            } else {
                searchForTrailingAnnotations(codeLine: trimmedLine)
            }

            return Line(
                content: line,
                type: type,
                annotations: annotations
            )
        }
    }

    private func searchForTrailingAnnotations(codeLine: String) -> Annotations {
        let blockComponents = codeLine.components(separatedBy: "/*", excludingDelimiterBetween: ("", ""))
        if blockComponents.count > 1,
           let lastBlockComponent = blockComponents.last,
           let endBlockRange = lastBlockComponent.range(of: "*/"),
           let lowerBound = lastBlockComponent.range(of: "sourcery:")?.upperBound
        {
            let trailingStart = endBlockRange.upperBound
            let trailing = String(lastBlockComponent[trailingStart...])
            if trailing.components(separatedBy: "//", excludingDelimiterBetween: ("", "")).first?.trimmed.count == 0 {
                let upperBound = endBlockRange.lowerBound
                return try! argumentParser.parseArguments(from: String(lastBlockComponent[lowerBound ..< upperBound]))
            }
        }

        let components = codeLine.components(separatedBy: "//", excludingDelimiterBetween: ("", ""))
        if components.count > 1,
           let trailingComment = components.last?.stripped(),
           let lowerBound = trailingComment.range(of: "sourcery:")?.upperBound
        {
            return try! argumentParser.parseArguments(from: String(trailingComment[lowerBound...]))
        }

        return [:]
    }

    private func searchForAnnotations(commentLine: String) -> Annotations {
        let comment = commentLine.trimmingPrefix("///").trimmingPrefix("//").trimmingPrefix("/**").trimmingPrefix("/*").trimmingPrefix("*").stripped()

        guard comment.hasPrefix("sourcery:") else {
            return [:]
        }

        let lowerBound = commentLine.range(of: "sourcery:")?.upperBound
        let upperBound = if commentLine.hasPrefix("//") || commentLine.hasPrefix("*") {
            commentLine.indices.endIndex
        } else {
            commentLine.range(of: "*/")?.lowerBound
        }

        guard let lowerBound, let upperBound else {
            return [:]
        }

        return try! argumentParser.parseArguments(from: String(commentLine[lowerBound ..< upperBound]))
    }
}
