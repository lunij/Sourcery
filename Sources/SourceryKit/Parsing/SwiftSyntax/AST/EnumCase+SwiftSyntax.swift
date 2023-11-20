import Foundation
import SwiftSyntax

extension EnumCaseDeclSyntax {
    func enumCases(
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) -> [EnumCase] {
        let documentation = getDocumentationUseCase?.documentation(from: self) ?? []
        let caseElementAnnotationsMap = getAnnotationUseCase.parseAnnotations(from: self)
        return caseElementAnnotationsMap.map { element, annotations in
            EnumCase(
                element,
                parent: self,
                getAnnotationUseCase: getAnnotationUseCase,
                annotations: annotations,
                documentation: documentation
            )
        }
    }
}

extension EnumCase {
    fileprivate init(
        _ node: EnumCaseElementSyntax,
        parent: EnumCaseDeclSyntax,
        getAnnotationUseCase: GetAnnotationUseCase,
        annotations: Annotations,
        documentation: Documentation
    ) {
        var associatedValues: [AssociatedValue] = []

        if let parameterClause = node.parameterClause {
            let parameterAnnotationsMap = getAnnotationUseCase.parseAnnotations(from: parameterClause)

            let hasManyValues = parameterAnnotationsMap.count > 1

            associatedValues = parameterAnnotationsMap.enumerated().map { index, parameterWithAnnotations in
                let parameter = parameterWithAnnotations.parameter
                let name = parameter.firstName?.text.trimmed.nilIfNotValidParameterName
                let secondName = parameter.secondName?.text.trimmed

                let defaultValue = parameter.defaultValue?.value.description.trimmed

                var externalName: String? = secondName
                if externalName == nil, hasManyValues {
                    externalName = name ?? "\(index)"
                }

                return AssociatedValue(
                    localName: name,
                    externalName: externalName,
                    typeName: .init(parameter.type),
                    type: nil,
                    defaultValue: defaultValue,
                    annotations: parameterWithAnnotations.annotations
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
            annotations: annotations,
            documentation: documentation,
            indirect: indirect
        )
    }
}
