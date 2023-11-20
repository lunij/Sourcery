import Foundation
import SwiftSyntax

extension Subscript {
    convenience init(
        _ node: SubscriptDeclSyntax,
        parent: Type,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        let modifiers = node.modifiers.map(Modifier.init)
        let baseModifiers = modifiers.baseModifiers(parent: parent)
        let parentAccess = AccessLevel(rawValue: parent.accessLevel) ?? .internal

        var writeAccess = baseModifiers.writeAccess
        var readAccess = baseModifiers.readAccess
        var hadGetter = false
        var hadSetter = false

        if let block = node
          .accessorBlock?
          .as(AccessorBlockSyntax.self) {
            enum Kind: String {
                case get
                case set
            }

            let computeAccessors = switch block.accessors {
            case let .accessors(accessors):
                Set(accessors.compactMap { accessor in
                    Kind(rawValue: accessor.accessorSpecifier.text.trimmed)
                })
            case let .getter(itemList):
                Set(itemList.compactMap { item in
                    Kind(rawValue: item.trimmedDescription)
                })
            }

            if !computeAccessors.isEmpty {
                if !computeAccessors.contains(Kind.set) {
                    writeAccess = .none
                } else {
                    hadSetter = true
                }

                if !computeAccessors.contains(Kind.get) {
                } else {
                    hadGetter = true
                }
            }
        } else if node.accessorBlock != nil {
            hadGetter = true
        }

        let isComputed = hadGetter && !(parent is SourceryProtocol)
        let isWritable = (!(parent is SourceryProtocol) && !isComputed) || hadSetter

        if parent is SourceryProtocol {
            writeAccess = parentAccess
            readAccess = parentAccess
        }

        let parameterAnnotationsMap = getAnnotationUseCase.parseAnnotations(from: node.parameterClause)

        self.init(
            parameters: parameterAnnotationsMap.map { FunctionParameter($0.parameter, annotations: $0.annotations) },
            returnTypeName: TypeName(node.returnClause.type.description.trimmed),
            accessLevel: (read: readAccess, write: isWritable ? writeAccess : .none),
            attributes: .init(from: node.attributes),
            modifiers: modifiers,
            annotations: node.firstToken(viewMode: .sourceAccurate).map { getAnnotationUseCase.parseAnnotations(from: $0) } ?? [:],
            documentation: node.firstToken(viewMode: .sourceAccurate).map { getDocumentationUseCase?.documentation(from: $0) ?? [] } ?? [],
            definedInTypeName: TypeName(parent.name)
        )
    }
}
