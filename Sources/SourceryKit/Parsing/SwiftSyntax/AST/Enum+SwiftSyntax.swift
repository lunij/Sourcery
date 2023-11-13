import Foundation
import SwiftSyntax

extension Enum {
    convenience init(_ node: EnumDeclSyntax, parent: Type?, getAnnotationUseCase: GetAnnotationUseCase) {
        let modifiers = node.modifiers.map(Modifier.init)

        //let rawTypeName: String? = node.inheritanceClause?.inheritedTypeCollection.first?.typeName.description.trimmed ?? nil
        self.init(
            name: node.name.text.trimmingCharacters(in: .whitespaces),
          parent: parent,
          accessLevel: modifiers.lazy.compactMap(AccessLevel.init).first ?? .default(for: parent),
          isExtension: false,
            inheritedTypes: node.inheritanceClause?.inheritedTypes.map { $0.type.description.trimmed } ?? [], // TODO: type name?
          rawTypeName: nil,
          cases: [],
          variables: [],
          methods: [],
          containedTypes: [],
          typealiases: [],
            attributes: .init(from: node.attributes),
          modifiers: modifiers,
          annotations: getAnnotationUseCase.annotations(from: node),
          documentation: getAnnotationUseCase.documentation(from: node),
            isGeneric: node.genericParameterClause?.parameters.isEmpty == false
        )
    }
}
