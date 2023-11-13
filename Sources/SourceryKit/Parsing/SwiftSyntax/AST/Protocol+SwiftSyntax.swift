import Foundation
import SwiftSyntax

extension SourceryProtocol {
    convenience init(_ node: ProtocolDeclSyntax, parent: Type?, getAnnotationParser: GetAnnotationUseCase) {
        let modifiers = node.modifiers.map(Modifier.init)

        let genericRequirements: [GenericRequirement] = node.genericWhereClause?.requirements.compactMap { requirement in
            if let sameType = requirement.requirement.as(SameTypeRequirementSyntax.self) {
                return GenericRequirement(sameType)
            } else if let conformanceType = requirement.requirement.as(ConformanceRequirementSyntax.self) {
                return GenericRequirement(conformanceType)
            }
            return nil
        } ?? []

        self.init(
          name: node.name.text.trimmingCharacters(in: .whitespaces),
          parent: parent,
          accessLevel: modifiers.lazy.compactMap(AccessLevel.init).first ?? .internal,
          isExtension: false,
          variables: [],
          methods: [],
          subscripts: [],
          inheritedTypes: node.inheritanceClause?.inheritedTypes.map { $0.type.description.trimmed } ?? [],
          containedTypes: [],
          typealiases: [],
          genericRequirements: genericRequirements,
          attributes: .init(from: node.attributes),
          modifiers: modifiers,
          annotations: getAnnotationParser.annotations(from: node),
          documentation: getAnnotationParser.documentation(from: node)
        )
    }
}
