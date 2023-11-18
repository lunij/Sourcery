import SwiftSyntax

public struct FunctionSignature {
    /// The function inputs.
    public let parameters: [FunctionParameter]

    /// The function output, if any.
    public let returnType: TypeName?

    /// The `async` keyword, if any.
    public let asyncKeyword: String?

    /// The `throws` or `rethrows` keyword, if any.
    public let throwsOrRethrowsKeyword: String?

    public init(_ node: FunctionSignatureSyntax, getAnnotationUseCase: GetAnnotationUseCase) {
        self.init(
            parameters: node.parameterClause.parameters.map { FunctionParameter($0, getAnnotationUseCase: getAnnotationUseCase) },
            returnType: node.returnClause.map { TypeName($0.type) },
            asyncKeyword: node.effectSpecifiers?.asyncSpecifier?.text,
            throwsOrRethrowsKeyword: node.effectSpecifiers?.throwsSpecifier?.trimmedDescription
        )
    }

    public init(
        parameters: [FunctionParameter],
        returnType: TypeName? = nil,
        asyncKeyword: String? = nil,
        throwsOrRethrowsKeyword: String? = nil
    ) {
        self.parameters = parameters
        self.returnType = returnType
        self.asyncKeyword = asyncKeyword
        self.throwsOrRethrowsKeyword = throwsOrRethrowsKeyword
    }

    public func definition(with name: String) -> String {
        let parameters = parameters.map(\.description).joined(separator: ", ")
        return "\(name)(\(parameters))"
    }

    public func selector(with name: String) -> String {
        if parameters.isEmpty {
            return name
        }

        let parameters = parameters
          .map { "\($0.argumentLabel ?? "_"):" }
          .joined(separator: "")

        return "\(name)(\(parameters))"
    }
}
