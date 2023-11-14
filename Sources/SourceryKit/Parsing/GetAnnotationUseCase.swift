import SwiftSyntax

public class GetAnnotationUseCase {
    private let annotationParser: AnnotationParser
    private let lines: [AnnotationParser.Line]
    private var sourceLocationConverter: SourceLocationConverter?

    var all: Annotations {
        var all = Annotations()
        lines.forEach {
            $0.annotations.forEach {
                all.append(key: $0.key, value: $0.value)
            }
        }
        return all
    }

    convenience init(
        content: String,
        annotationParser: AnnotationParser = AnnotationParser(),
        sourceLocationConverter: SourceLocationConverter? = nil
    ) {
        self.init(
            annotationParser: annotationParser,
            lines: annotationParser.parse(content),
            sourceLocationConverter: sourceLocationConverter
        )
    }

    init(
        annotationParser: AnnotationParser,
        lines: [AnnotationParser.Line],
        sourceLocationConverter: SourceLocationConverter? = nil
    ) {
        self.annotationParser = annotationParser
        self.lines = lines
        self.sourceLocationConverter = sourceLocationConverter
    }

    func annotations(from node: IdentifierSyntax) -> Annotations {
        from(
            location: findLocation(syntax: node.identifier),
            precedingComments: node.leadingTrivia.compactMap(\.comment)
        )
    }

    func annotations(fromToken token: SyntaxProtocol) -> Annotations {
        from(
            location: findLocation(syntax: token),
            precedingComments: token.leadingTrivia.compactMap(\.comment)
        )
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
            annotations.append(key: annotation.key, value: annotation.value)
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
            for annotation in annotationParser.parse(comment)[0].annotations {
                annotations.append(key: annotation.key, value: annotation.value)
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
        var stop = false
        var annotations = inlineFrom(line: (location.line, location.column), stop: &stop)
        guard !stop else { return annotations }

        for line in lines[0 ..< location.line - 1].reversed() {
            line.annotations.forEach { annotation in
                annotations.append(key: annotation.key, value: annotation.value)
            }
            if line.type != .comment && line.type != .documentationComment {
                break
            }
        }

        lines[location.line - 1].annotations.forEach { annotation in
            annotations.append(key: annotation.key, value: annotation.value)
        }

        return annotations
    }
}
