import Foundation
import SwiftSyntax

extension Struct {
    convenience init(_ node: StructDeclSyntax, parent: Type?, getAnnotationUseCase: GetAnnotationUseCase) {
        let modifiers = node.modifiers.map(SModifier.init)

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
            attributes: Attribute.from(node.attributes),
            modifiers: modifiers.map(SourceryModifier.init),
            annotations: getAnnotationUseCase.annotations(from: node),
            documentation: getAnnotationUseCase.documentation(from: node),
            isGeneric: node.genericParameterClause?.parameters.isEmpty == false
        )
    }
}
