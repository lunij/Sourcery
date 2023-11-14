import Foundation
import SwiftSyntax

struct AnnotationParser {
    enum AnnotationType {
        case begin(Annotations)
        case annotations(Annotations)
        case end
        case inlineStart
        case file(Annotations)
    }

    struct Line {
        enum LineType {
            case comment
            case documentationComment
            case blockStart
            case blockEnd
            case other
            case inlineStart
            case inlineEnd
            case file
        }

        let content: String
        let type: LineType
        let annotations: Annotations
        let blockAnnotations: Annotations
    }

    let argumentParser = AnnotationArgumentParser()

    func parse(contents: String) -> [Line] {
        var annotationsBlock: Annotations?
        var fileAnnotationsBlock = Annotations()
        return StringView(contents).lines
            .map { line in
                let content = line.content.trimmingCharacters(in: .whitespaces)
                var annotations = Annotations()
                let isComment = content.hasPrefix("//") || content.hasPrefix("/*") || content.hasPrefix("*")
                let isDocumentationComment = content.hasPrefix("///") || content.hasPrefix("/**")
                var type = Line.LineType.other
                if isDocumentationComment {
                    type = .documentationComment
                } else if isComment {
                    type = .comment
                }
                if isComment {
                    switch searchForAnnotations(commentLine: content) {
                    case let .begin(items):
                        type = .blockStart
                        annotationsBlock = Annotations()
                        items.forEach { annotationsBlock?[$0.key] = $0.value }
                    case let .annotations(items):
                        items.forEach { annotations[$0.key] = $0.value }
                    case .end:
                        if annotationsBlock != nil {
                            type = .blockEnd
                            annotationsBlock?.removeAll()
                        } else {
                            type = .inlineEnd
                        }
                    case .inlineStart:
                        type = .inlineStart
                    case let .file(items):
                        type = .file
                        items.forEach {
                            fileAnnotationsBlock[$0.key] = $0.value
                        }
                    }
                } else {
                    searchForTrailingAnnotations(codeLine: content)
                        .forEach { annotations[$0.key] = $0.value }
                }

                annotationsBlock?.forEach { annotation in
                    annotations[annotation.key] = annotation.value
                }

                fileAnnotationsBlock.forEach { annotation in
                    annotations[annotation.key] = annotation.value
                }

                return Line(
                    content: line.content,
                    type: type,
                    annotations: annotations,
                    blockAnnotations: annotationsBlock ?? [:]
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
                return argumentParser.parseArguments(from: String(lastBlockComponent[lowerBound ..< upperBound]))
            }
        }

        let components = codeLine.components(separatedBy: "//", excludingDelimiterBetween: ("", ""))
        if components.count > 1,
           let trailingComment = components.last?.stripped(),
           let lowerBound = trailingComment.range(of: "sourcery:")?.upperBound
        {
            return argumentParser.parseArguments(from: String(trailingComment[lowerBound...]))
        }

        return [:]
    }

    private func searchForAnnotations(commentLine: String) -> AnnotationType {
        let comment = commentLine.trimmingPrefix("///").trimmingPrefix("//").trimmingPrefix("/**").trimmingPrefix("/*").trimmingPrefix("*").stripped()

        guard comment.hasPrefix("sourcery:") else { return .annotations([:]) }

        if comment.hasPrefix("sourcery:inline:") {
            return .inlineStart
        }

        let lowerBound: String.Index?
        let upperBound: String.Index?
        var insideBlock = false
        var insideFileBlock = false

        if comment.hasPrefix("sourcery:begin:") {
            lowerBound = commentLine.range(of: "sourcery:begin:")?.upperBound
            upperBound = commentLine.indices.endIndex
            insideBlock = true
        } else if comment.hasPrefix("sourcery:end") {
            return .end
        } else if comment.hasPrefix("sourcery:file") {
            lowerBound = commentLine.range(of: "sourcery:file:")?.upperBound
            upperBound = commentLine.indices.endIndex
            insideFileBlock = true
        } else {
            lowerBound = commentLine.range(of: "sourcery:")?.upperBound
            if commentLine.hasPrefix("//") || commentLine.hasPrefix("*") {
                upperBound = commentLine.indices.endIndex
            } else {
                upperBound = commentLine.range(of: "*/")?.lowerBound
            }
        }

        if let lowerBound, let upperBound {
            let annotations = argumentParser.parseArguments(from: String(commentLine[lowerBound ..< upperBound]))
            if insideBlock {
                return .begin(annotations)
            } else if insideFileBlock {
                return .file(annotations)
            } else {
                return .annotations(annotations)
            }
        } else {
            return .annotations([:])
        }
    }
}
