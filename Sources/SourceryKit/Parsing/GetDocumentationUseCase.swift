import SwiftSyntax

class GetDocumentationUseCase {
    func documentation(from node: SyntaxProtocol) -> Documentation {
        node.leadingTrivia.pieces.compactMap {
            switch $0 {
            case let .docLineComment(value), let .docBlockComment(value):
                return value
            default:
                return nil
            }
        }
    }
}
