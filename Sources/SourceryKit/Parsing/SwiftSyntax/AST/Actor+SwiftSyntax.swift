import Foundation
import SwiftSyntax

extension Actor {
    convenience init(
        _ node: ActorDeclSyntax,
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
          variables: [],
          methods: [],
          subscripts: [],
          inheritedTypes: node.inheritanceClause?.inheritedTypes.map { $0.type.description.trimmed } ?? [],
          containedTypes: [],
          typealiases: [],
          attributes: .init(from: node.attributes),
          modifiers: modifiers,
          annotations: getAnnotationUseCase.annotations(from: node),
          documentation: getDocumentationUseCase?.documentation(from: node) ?? [],
          isGeneric: node.genericParameterClause?.parameters.isEmpty == false
        )
    }
}
