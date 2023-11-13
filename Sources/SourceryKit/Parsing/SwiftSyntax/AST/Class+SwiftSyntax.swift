import Foundation
import SwiftSyntax

extension Class {
    convenience init(_ node: ClassDeclSyntax, parent: Type?, getAnnotationUseCase: GetAnnotationUseCase) {
        let modifiers = node.modifiers.map(SModifier.init)

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
          modifiers: modifiers.map(SourceryModifier.init),
          annotations: getAnnotationUseCase.annotations(from: node),
          documentation: getAnnotationUseCase.documentation(from: node),
            isGeneric: node.genericParameterClause?.parameters.isEmpty == false
        )
    }
}
