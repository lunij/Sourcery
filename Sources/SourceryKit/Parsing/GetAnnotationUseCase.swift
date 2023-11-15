import SwiftSyntax

public class GetAnnotationUseCase {
    private let annotationParser: AnnotationParser
    private let lines: [AnnotationParser.Line]
    private var sourceLocationConverter: SourceLocationConverter

    convenience init(
        content: String,
        annotationParser: AnnotationParser = AnnotationParser(),
        sourceLocationConverter: SourceLocationConverter
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
        sourceLocationConverter: SourceLocationConverter
    ) {
        self.annotationParser = annotationParser
        self.lines = lines
        self.sourceLocationConverter = sourceLocationConverter
    }

    func annotations(from node: IdentifierSyntax) -> Annotations {
        annotations(
            at: findLocation(syntax: node.identifier),
            trivia: node.leadingTrivia
        )
    }

    func annotations(fromToken token: SyntaxProtocol) -> Annotations {
        annotations(
            at: findLocation(syntax: token),
            trivia: token.leadingTrivia
        )
    }

    private func findLocation(syntax: SyntaxProtocol) -> SourceLocation {
        sourceLocationConverter.location(for: syntax.positionAfterSkippingLeadingTrivia)
    }

    private func annotations(at location: SourceLocation, trivia: Trivia) -> Annotations {
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

    private func inlineFrom(line lineInfo: (line: Int, character: Int), stop: inout Bool) -> Annotations {
        let sourceLine = lines[lineInfo.line - 1]
        var prefix = sourceLine.content.bridge()
            .substring(to: max(0, lineInfo.character - 1))
            .trimmingCharacters(in: .whitespaces)

        guard !prefix.isEmpty else { return [:] }
        var annotations = sourceLine.blockAnnotations
        sourceLine.annotations.forEach { annotation in
            annotations.append(key: annotation.key, value: annotation.value)
        }

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
}
