import SwiftSyntax

extension Enum {
    convenience init(
        _ node: EnumDeclSyntax,
        parent: Type?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        let modifiers = node.modifiers.map(Modifier.init)

        self.init(
            name: node.name.text.trimmingCharacters(in: .whitespaces),
            parent: parent,
            accessLevel: modifiers.lazy.compactMap(AccessLevel.init).first ?? .default(for: parent),
            isExtension: false,
            inheritedTypes: node.inheritanceClause?.inheritedTypes.map(\.type.description.trimmed) ?? [], // TODO: type name?
            rawTypeName: nil,
            cases: [],
            variables: [],
            methods: [],
            containedTypes: [],
            typealiases: [],
            attributes: .init(from: node.attributes),
            modifiers: modifiers,
            annotations: getAnnotationUseCase.parseAnnotations(from: node),
            documentation: getDocumentationUseCase?.documentation(from: node) ?? [],
            isGeneric: node.genericParameterClause?.parameters.isEmpty == false
        )
    }
}
