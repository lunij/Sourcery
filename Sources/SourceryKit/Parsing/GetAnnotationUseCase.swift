import SwiftSyntax

public class GetAnnotationUseCase {
    private let annotationParser: AnnotationParser
    private let lines: [AnnotationParser.Line]
    private var sourceLocationConverter: SourceLocationConverter?
    private var parseDocumentation: Bool

    var all: Annotations {
        var all = Annotations()
        lines.forEach {
            $0.annotations.forEach {
                annotationParser.append(key: $0.key, value: $0.value, to: &all)
            }
        }
        return all
    }

    convenience init(
        content: String,
        annotationParser: AnnotationParser = AnnotationParser(),
        sourceLocationConverter: SourceLocationConverter? = nil,
        parseDocumentation: Bool = false
    ) {
        self.init(
            annotationParser: annotationParser,
            lines: annotationParser.parse(contents: content),
            sourceLocationConverter: sourceLocationConverter,
            parseDocumentation: parseDocumentation
        )
    }

    init(
        annotationParser: AnnotationParser,
        lines: [AnnotationParser.Line],
        sourceLocationConverter: SourceLocationConverter? = nil,
        parseDocumentation: Bool = false
    ) {
        self.annotationParser = annotationParser
        self.lines = lines
        self.sourceLocationConverter = sourceLocationConverter
        self.parseDocumentation = parseDocumentation
    }

    func annotations(from node: IdentifierSyntax) -> Annotations {
        from(
            location: findLocation(syntax: node.identifier),
            precedingComments: node.leadingTrivia?.compactMap({ $0.comment }) ?? []
        )
    }

    func annotations(fromToken token: SyntaxProtocol) -> Annotations {
        from(
            location: findLocation(syntax: token),
            precedingComments: token.leadingTrivia?.compactMap({ $0.comment }) ?? []
        )
    }

    func documentation(from node: IdentifierSyntax) -> Documentation {
        guard parseDocumentation else {
            return  []
        }
        return documentationFrom(
            location: findLocation(syntax: node.identifier),
            precedingComments: node.leadingTrivia?.compactMap({ $0.comment }) ?? []
        )
    }

    func documentation(fromToken token: SyntaxProtocol) -> Documentation {
        guard parseDocumentation else {
            return  []
        }
        return documentationFrom(
            location: findLocation(syntax: token),
            precedingComments: token.leadingTrivia?.compactMap({ $0.comment }) ?? []
        )
    }

    private func documentationFrom(location: SwiftSyntax.SourceLocation, precedingComments: [String]) -> Documentation {
        guard parseDocumentation,
              let lineNumber = location.line, let column = location.column else {
            return []
        }

        // Inline documentation not currently supported
        _ = column

        // var stop = false
        // var documentation = inlineDocumentationFrom(line: (lineNumber, column), stop: &stop)
        // guard !stop else { return annotations }

        var documentation: Documentation = []

        for line in lines[0..<lineNumber-1].reversed() {
            if line.type == .documentationComment {
                documentation.append(line.content.trimmingCharacters(in: .whitespaces).trimmingPrefix("///").trimmingPrefix("/**").trimmingPrefix(" "))
            }
            if line.type != .comment && line.type != .documentationComment {
                break
            }
        }

        return documentation.reversed()
    }

    private func findLocation(syntax: SyntaxProtocol) -> SwiftSyntax.SourceLocation {
        sourceLocationConverter!.location(for: syntax.positionAfterSkippingLeadingTrivia)
    }

    func inlineFrom(line lineInfo: (line: Int, character: Int), stop: inout Bool) -> Annotations {
        let sourceLine = lines[lineInfo.line - 1]
        var prefix = sourceLine.content.bridge()
            .substring(to: max(0, lineInfo.character - 1))
            .trimmingCharacters(in: .whitespaces)

        guard !prefix.isEmpty else { return [:] }
        var annotations = sourceLine.blockAnnotations // get block annotations for this line
        sourceLine.annotations.forEach { annotation in  // TODO: verify
            annotationParser.append(key: annotation.key, value: annotation.value, to: &annotations)
        }

        // `case` is not included in the key of enum case definition, so we strip it manually
        let isInsideCaseDefinition = prefix.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("case")
        prefix = prefix.trimmingPrefix("case").trimmingCharacters(in: .whitespaces)
        var inlineCommentFound = false

        while !prefix.isEmpty {
            guard prefix.hasSuffix("*/"), let commentStart = prefix.range(of: "/*", options: [.backwards]) else {
                break
            }

            inlineCommentFound = true

            let comment = String(prefix[commentStart.lowerBound...])
            for annotation in annotationParser.parse(contents: comment)[0].annotations {
                annotationParser.append(key: annotation.key, value: annotation.value, to: &annotations)
            }
            prefix = prefix[..<commentStart.lowerBound].trimmingCharacters(in: .whitespaces)
        }

        if (inlineCommentFound || isInsideCaseDefinition) && !prefix.isEmpty {
            stop = true
            return annotations
        }

        // if previous line is not comment or has some trailing non-comment blocks
        // we return currently aggregated annotations
        // as annotations on previous line belong to previous declaration
        if lineInfo.line - 2 > 0 {
            let previousLine = lines[lineInfo.line - 2]
            let content = previousLine.content.trimmingCharacters(in: .whitespaces)

            guard previousLine.type == .comment || previousLine.type == .documentationComment, content.hasPrefix("//") || content.hasSuffix("*/") else {
                stop = true
                return annotations
            }
        }

        return annotations
    }

    func from(location: SwiftSyntax.SourceLocation, precedingComments: [String]) -> Annotations {
        guard let lineNumber = location.line, let column = location.column else {
            return [:]
        }

        var stop = false
        var annotations = inlineFrom(line: (lineNumber, column), stop: &stop)
        guard !stop else { return annotations }

        for line in lines[0..<lineNumber-1].reversed() {
            line.annotations.forEach { annotation in
                annotationParser.append(key: annotation.key, value: annotation.value, to: &annotations)
            }
            if line.type != .comment && line.type != .documentationComment {
                break
            }
        }

        lines[lineNumber-1].annotations.forEach { annotation in
            annotationParser.append(key: annotation.key, value: annotation.value, to: &annotations)
        }

        return annotations
    }
}
