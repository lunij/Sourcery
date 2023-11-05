import SwiftSyntax

extension MethodParameter {
    convenience init(_ node: FunctionParameterSyntax, getAnnotationUseCase: GetAnnotationUseCase) {
        let firstName = node.firstName?.text.trimmed.nilIfNotValidParameterName

        let typeName = node.type.map { TypeName($0) } ?? TypeName.unknown(description: node.description.trimmed)
        let specifiers = TypeName.specifiers(from: node.type)
        
        if specifiers.isInOut {
            // TODO: TBR
            typeName.name = "inout \(typeName.name)"
        }
        
        self.init(
          argumentLabel: firstName,
          name: node.secondName?.text.trimmed ?? firstName ?? "",
          typeName: typeName,
          type: nil,
          defaultValue: node.defaultArgument?.value.description.trimmed,
          annotations: node.firstToken.map { getAnnotationUseCase.annotations(fromToken: $0) } ?? [:],
          isInout: specifiers.isInOut,
          isVariadic: node.type?.as(PackExpansionTypeSyntax.self)?.ellipsis != nil
        )
    }
}
