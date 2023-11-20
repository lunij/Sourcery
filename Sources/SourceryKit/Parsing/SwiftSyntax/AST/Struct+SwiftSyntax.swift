import Foundation
import SwiftSyntax

extension Struct {
    convenience init(
        _ node: StructDeclSyntax,
        parent: Type?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        let modifiers = node.modifiers.map(Modifier.init)

        self.init(
            name: node.name.text.trimmed,
            parent: parent,
            accessLevel: modifiers.lazy.compactMap(AccessLevel.init).first ?? .default(for: parent),
            isExtension: false,
            variables: [],
            methods: [],
            subscripts: [],
            inheritedTypes: node.inheritanceClause?.inheritedTypes.map { $0.type.description.trimmed } ?? [],
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
