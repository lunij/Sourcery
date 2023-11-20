import SwiftSyntax

protocol IdentifierSyntax: SyntaxProtocol {
    var identifier: TokenSyntax { get }
}

extension ActorDeclSyntax: IdentifierSyntax {}

extension ClassDeclSyntax: IdentifierSyntax {}

extension StructDeclSyntax: IdentifierSyntax {}

extension EnumDeclSyntax: IdentifierSyntax {}

extension ProtocolDeclSyntax: IdentifierSyntax {}

extension FunctionDeclSyntax: IdentifierSyntax {}

extension TypeAliasDeclSyntax: IdentifierSyntax {}

extension OperatorDeclSyntax: IdentifierSyntax {}

extension EnumCaseElementSyntax: IdentifierSyntax {}
