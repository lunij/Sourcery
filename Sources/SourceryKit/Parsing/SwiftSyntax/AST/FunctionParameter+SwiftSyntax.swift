import SwiftSyntax

extension FunctionParameter {
    convenience init(_ node: FunctionParameterSyntax, getAnnotationUseCase: GetAnnotationUseCase) {
        let firstName = node.firstName.text.trimmed.nilIfNotValidParameterName

        let typeName = TypeName(node.type)
        let specifiers = TypeName.specifiers(from: node.type)

        if specifiers.isInOut {
            // TODO: TBR
            typeName.name = "inout \(typeName.name)"
        }

        self.init(
            argumentLabel: firstName,
            name: node.secondName?.text.trimmed ?? firstName ?? "",
            typeName: typeName,
            type: nil, // will be set during resolving process
            defaultValue: node.defaultValue?.value.description.trimmed,
            annotations: node.firstToken(viewMode: .sourceAccurate).map { getAnnotationUseCase.annotations(fromToken: $0) } ?? [:],
            isInout: specifiers.isInOut,
            isVariadic: node.ellipsis != nil
        )
    }
}
