import Foundation
import SwiftSyntax

extension EnumCase {

    convenience init(_ node: EnumCaseElementSyntax, parent: EnumCaseDeclSyntax, getAnnotationUseCase: GetAnnotationUseCase) {
        var associatedValues: [AssociatedValue] = []
        if let paramList = node.associatedValue?.parameterList {
            let hasManyValues = paramList.count > 1
            associatedValues = paramList
              .enumerated()
              .map { (idx, param) in
                  let name = param.firstName?.text.trimmed.nilIfNotValidParameterName
                  let secondName = param.secondName?.text.trimmed

                  let defaultValue = param.defaultArgument?.value.description.trimmed
                  var externalName: String? = secondName
                  if externalName == nil, hasManyValues {
                      externalName = name ?? "\(idx)"
                  }

                  var collectedAnnotations = Annotations()
                  if let typeSyntax = param.type {
                      collectedAnnotations = getAnnotationUseCase.annotations(fromToken: typeSyntax)
                  }

                  return AssociatedValue(localName: name,
                                         externalName: externalName,
                                         typeName: param.type.map { TypeName($0) } ?? TypeName.unknown(description: parent.description.trimmed),
                                         type: nil,
                                         defaultValue: defaultValue,
                                         annotations: collectedAnnotations
                  )
              }
        }

        let rawValue: String? = {
            var value = node.rawValue?.withEqual(nil).description.trimmed
            if let unwrapped = value, unwrapped.hasPrefix("\""), unwrapped.hasSuffix("\""), unwrapped.count > 2 {
                let substring = unwrapped[unwrapped.index(after: unwrapped.startIndex) ..< unwrapped.index(before: unwrapped.endIndex)]
                value = String(substring)
            }
            return value
        }()

        let modifiers = parent.modifiers?.map(SModifier.init) ?? []
        let indirect = modifiers.contains(where: {
            $0.tokenKind == TokenKind.contextualKeyword("indirect")
        })

        self.init(
          name: node.identifier.text.trimmed,
          rawValue: rawValue,
          associatedValues: associatedValues,
          annotations: getAnnotationUseCase.annotations(from: node),
          documentation: getAnnotationUseCase.documentation(from: node),
          indirect: indirect
        )
    }

    static func from(_ node: EnumCaseDeclSyntax, getAnnotationUseCase: GetAnnotationUseCase) -> [EnumCase] {
        node.elements.compactMap {
            EnumCase($0, parent: node, getAnnotationUseCase: getAnnotationUseCase)
        }
    }
}
