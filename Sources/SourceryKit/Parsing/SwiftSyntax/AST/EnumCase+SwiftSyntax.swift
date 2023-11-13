import Foundation
import SwiftSyntax

extension EnumCase {

    convenience init(_ node: EnumCaseElementSyntax, parent: EnumCaseDeclSyntax, getAnnotationUseCase: GetAnnotationUseCase) {
        var associatedValues: [AssociatedValue] = []
        if let paramList = node.parameterClause?.parameters {
            let hasManyValues = paramList.count > 1
            associatedValues = paramList
              .enumerated()
              .map { (idx, param) in
                  let name = param.firstName?.text.trimmed.nilIfNotValidParameterName
                  let secondName = param.secondName?.text.trimmed

                  let defaultValue = param.defaultValue?.value.description.trimmed
                  var externalName: String? = secondName
                  if externalName == nil, hasManyValues {
                      externalName = name ?? "\(idx)"
                  }

                  var collectedAnnotations = Annotations()
                  collectedAnnotations = getAnnotationUseCase.annotations(fromToken: param.type)

                  return AssociatedValue(localName: name,
                                         externalName: externalName,
                                         typeName: .init(param.type),
                                         type: nil,
                                         defaultValue: defaultValue,
                                         annotations: collectedAnnotations
                  )
              }
        }

        var rawValue = node.rawValue?.value.trimmedDescription
        if let unwrapped = rawValue, unwrapped.hasPrefix("\""), unwrapped.hasSuffix("\""), unwrapped.count > 2 {
            let substring = unwrapped[unwrapped.index(after: unwrapped.startIndex) ..< unwrapped.index(before: unwrapped.endIndex)]
            rawValue = String(substring)
        }

        let modifiers = parent.modifiers.map(Modifier.init)
        let indirect = modifiers.contains { $0.name == "indirect" }

        self.init(
          name: node.name.text.trimmed,
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
