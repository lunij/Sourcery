import Foundation
import SwiftSyntax

extension Actor {
    convenience init(_ node: ActorDeclSyntax, parent: Type?, getAnnotationUseCase: GetAnnotationUseCase) {
        let modifiers = node.modifiers?.map(SModifier.init) ?? []

        self.init(
          name: node.identifier.text.trimmingCharacters(in: .whitespaces),
          parent: parent,
          accessLevel: modifiers.lazy.compactMap(AccessLevel.init).first ?? .default(for: parent),
          isExtension: false,
          variables: [],
          methods: [],
          subscripts: [],
          inheritedTypes: node.inheritanceClause?.inheritedTypeCollection.map { $0.typeName.description.trimmed } ?? [],
          containedTypes: [],
          typealiases: [],
          attributes: Attribute.from(node.attributes),
          modifiers: modifiers.map(SourceryModifier.init),
          annotations: getAnnotationUseCase.annotations(from: node),
          documentation: getAnnotationUseCase.documentation(from: node),
          isGeneric: node.genericParameterClause?.genericParameterList.isEmpty == false
        )
    }
}
