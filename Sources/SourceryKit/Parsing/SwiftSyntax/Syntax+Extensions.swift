import SwiftSyntax

public extension TriviaPiece {
    /// Returns string value of a comment piece or nil otherwise
    var comment: String? {
        switch self {
        case .spaces,
             .tabs,
             .verticalTabs,
             .formfeeds,
             .newlines,
             .carriageReturns,
             .carriageReturnLineFeeds,
             .unexpectedText,
             .shebang:
            nil
        case let .lineComment(comment),
             let .blockComment(comment),
             let .docLineComment(comment),
             let .docBlockComment(comment):
            comment
        }
    }
}

// seems to be bug in SwiftSyntax
public protocol AsyncThrowsFixup {
    var asyncKeyword: TokenSyntax? { get }
    var throwsKeyword: TokenSyntax? { get }

    var fixedAsyncKeyword: TokenSyntax? { get }
    var fixedThrowsKeyword: TokenSyntax? { get }
}

public protocol AsyncReThrowsFixup {
    var asyncKeyword: TokenSyntax? { get }
    var throwsOrRethrowsKeyword: TokenSyntax? { get }

    var fixedAsyncKeyword: TokenSyntax? { get }
    var fixedThrowsOrRethrowsKeyword: TokenSyntax? { get }
}

public extension AsyncThrowsFixup {
    var fixedAsyncKeyword: TokenSyntax? {
        if asyncKeyword?.tokenKind == .throwsKeyword {
            return nil
        }

        return asyncKeyword
    }

    var fixedThrowsKeyword: TokenSyntax? {
        if asyncKeyword?.tokenKind == .throwsKeyword, throwsKeyword == nil {
            asyncKeyword
        } else {
            throwsKeyword
        }
    }
}

public extension AsyncReThrowsFixup {
    var fixedAsyncKeyword: TokenSyntax? {
        if asyncKeyword?.tokenKind == .throwsKeyword {
            return nil
        }

        return asyncKeyword
    }

    var fixedThrowsOrRethrowsKeyword: TokenSyntax? {
        if asyncKeyword?.tokenKind == .throwsKeyword, throwsOrRethrowsKeyword == nil {
            asyncKeyword
        } else {
            throwsOrRethrowsKeyword
        }
    }
}

extension AccessorListSyntax.Element: AsyncThrowsFixup {}
extension FunctionTypeSyntax: AsyncReThrowsFixup {}

protocol IdentifierSyntax: SyntaxProtocol {
    var identifier: TokenSyntax { get }
}

extension ActorDeclSyntax: IdentifierSyntax {}

extension ClassDeclSyntax: IdentifierSyntax {}

extension StructDeclSyntax: IdentifierSyntax {}

extension EnumDeclSyntax: IdentifierSyntax {}

extension ProtocolDeclSyntax: IdentifierSyntax {}

extension FunctionDeclSyntax: IdentifierSyntax {}

extension TypealiasDeclSyntax: IdentifierSyntax {}

extension OperatorDeclSyntax: IdentifierSyntax {}

extension EnumCaseElementSyntax: IdentifierSyntax {}
