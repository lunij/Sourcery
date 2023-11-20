import SwiftSyntax

public class GetAnnotationUseCase {
    private let annotationParser = AnnotationParser()

    func parseAnnotations(from node: DeclSyntaxProtocol) -> Annotations {
        parse(from: node.leadingTrivia)
    }

    func parseAnnotations(from node: EnumCaseDeclSyntax) -> [(element: EnumCaseElementSyntax, annotations: Annotations)] {
        let allElementsAnnotations = parse(from: node.leadingTrivia)
        var annotationsOfNextParam: Annotations?
        return node.elements.enumerated().map { index, element in
            var annotations = allElementsAnnotations

            if index == 0 {
                for (key, value) in parse(from: node.caseKeyword.trailingTrivia) {
                    annotations[key] = value
                }
            }

            if let annotationsOfNextParam {
                for (key, value) in annotationsOfNextParam {
                    annotations[key] = value
                }
            }

            if let trailingComma = element.trailingComma {
                annotationsOfNextParam = parse(from: trailingComma.trailingTrivia)
            }

            return (element, annotations)
        }
    }

    func parseAnnotations(from node: ExtensionDeclSyntax) -> Annotations {
        if let firstModifier = node.modifiers.first {
            return parse(from: firstModifier.name.leadingTrivia)
        }
        return parse(from: node.extensionKeyword.leadingTrivia)
    }

    func parseAnnotations(from node: TokenSyntax) -> Annotations {
        parse(from: node.leadingTrivia)
    }

    func parseAnnotations(from parameterClause: EnumCaseParameterClauseSyntax) -> [(parameter: EnumCaseParameterSyntax, annotations: Annotations)] {
        var annotationsOfNextParam: Annotations?
        return parameterClause.parameters.enumerated().map { index, parameter in
            guard let typeName = parameter.type.as(IdentifierTypeSyntax.self)?.name else {
                return (parameter, [:])
            }
            var annotations = parseAnnotations(from: typeName)

            if index == 0 {
                for (key, value) in parse(from: parameterClause.leftParen.trailingTrivia) {
                    annotations[key] = value
                }
            }

            if let annotationsOfNextParam {
                for (key, value) in annotationsOfNextParam {
                    annotations[key] = value
                }
            }

            if let trailingComma = parameter.trailingComma {
                annotationsOfNextParam = parse(from: trailingComma.trailingTrivia)
            }

            return (parameter, annotations)
        }
    }

    func parseAnnotations(from parameterClause: FunctionParameterClauseSyntax) -> [(parameter: FunctionParameterSyntax, annotations: Annotations)] {
        var annotationsOfNextParam: Annotations?
        return parameterClause.parameters.enumerated().map { index, parameter in
            var annotations = parseAnnotations(from: parameter.firstName)

            if index == 0 {
                for (key, value) in parse(from: parameterClause.leftParen.trailingTrivia) {
                    annotations[key] = value
                }
            }

            if let annotationsOfNextParam {
                for (key, value) in annotationsOfNextParam {
                    annotations[key] = value
                }
            }

            if let trailingComma = parameter.trailingComma {
                annotationsOfNextParam = parse(from: trailingComma.trailingTrivia)
            }

            return (parameter, annotations)
        }
    }

    private func parse(from trivia: Trivia) -> Annotations {
        let comments = trivia.pieces.compactMap(\.comment)
        var annotations: Annotations = [:]

        for comment in comments {
            for (key, value) in annotationParser.parse(comment) {
                annotations.append(key: key, value: value)
            }
        }

        return annotations
    }
}

private extension TriviaPiece {
    var comment: String? {
        switch self {
        case let .lineComment(comment),
             let .blockComment(comment),
             let .docLineComment(comment),
             let .docBlockComment(comment):
            comment
        default:
            nil
        }
    }
}
