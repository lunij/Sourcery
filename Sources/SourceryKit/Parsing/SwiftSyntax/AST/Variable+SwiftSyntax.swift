import Foundation
import SwiftSyntax

extension Variable {
    convenience init(
        _ node: PatternBindingSyntax,
        variableNode: VariableDeclSyntax,
        readAccess: AccessLevel,
        writeAccess: AccessLevel,
        isStatic: Bool,
        modifiers: [Modifier],
        visitingType: Type?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        var writeAccess = writeAccess
        var hadGetter = false
        var hadSetter = false
        var hadAsync = false
        var hadThrowable = false

        if let block = node
          .accessorBlock?
          .as(AccessorBlockSyntax.self) {
            enum Kind: Hashable {
                case get(isAsync: Bool, throws: Bool)
                case set
            }

            let computeAccessors = switch block.accessors {
            case let .accessors(accessors):
                Set(accessors.compactMap { accessor in
                    let kindRaw = accessor.accessorSpecifier.text.trimmed
                    if kindRaw == "get" {
                        return Kind.get(
                            isAsync: accessor.effectSpecifiers?.asyncSpecifier != nil,
                            throws: accessor.effectSpecifiers?.throwsSpecifier != nil
                        )
                    }

                    if kindRaw == "set" {
                        return Kind.set
                    }

                    return nil
                })
            case let .getter(itemList):
                Set(itemList.compactMap { item in
                    Kind.get(isAsync: false, throws: false)
                })
            }

            if !computeAccessors.isEmpty {
                if !computeAccessors.contains(Kind.set) {
                    writeAccess = .none
                } else {
                    hadSetter = true
                }
                
                for accessor in computeAccessors {
                    if case let .get(isAsync: isAsync, throws: `throws`) = accessor {
                        hadGetter = true
                        hadAsync = isAsync
                        hadThrowable = `throws`
                        break
                    }
                }
            }
        } else if node.accessorBlock != nil {
            hadGetter = true
        }

        let isComputed = node.initializer == nil && hadGetter && !(visitingType is SourceryProtocol)
        let isAsync = hadAsync
        let `throws` = hadThrowable
        let isWritable = variableNode.bindingSpecifier.tokens(viewMode: .fixedUp).contains { $0.tokenKind == .keyword(.var) } && (!isComputed || hadSetter)

        let typeName = node.typeAnnotation.map { TypeName($0.type) } ??
          node.initializer.flatMap { Self.inferType($0.value.description.trimmed) }

        self.init(
            name: node.pattern.trimmedDescription,
          typeName: typeName ?? TypeName.unknown(description: node.description.trimmed),
          type: nil,
          accessLevel: (read: readAccess, write: isWritable ? writeAccess : .none),
          isComputed: isComputed,
          isAsync: isAsync,
          throws: `throws`,
          isStatic: isStatic,
          defaultValue: node.initializer?.value.description.trimmingCharacters(in: .whitespacesAndNewlines),
            attributes: .init(from: variableNode.attributes),
          modifiers: modifiers,
          annotations: getAnnotationUseCase.annotations(fromToken: variableNode.bindingSpecifier),
          documentation: getDocumentationUseCase?.documentation(from: variableNode.bindingSpecifier) ?? [],
          definedInTypeName: visitingType.map { TypeName($0.name) }
        )
    }

    static func from(
        _ variableNode: VariableDeclSyntax,
        visitingType: Type?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) -> [Variable] {
        let modifiers = variableNode.modifiers.map(Modifier.init)
        let baseModifiers = modifiers.baseModifiers(parent: visitingType)

        return variableNode.bindings.map { (node: PatternBindingSyntax) -> Variable in
            Variable(
                node,
                variableNode: variableNode,
                readAccess: baseModifiers.readAccess,
                writeAccess: baseModifiers.writeAccess,
                isStatic: baseModifiers.isStatic || baseModifiers.isClass,
                modifiers: modifiers,
                visitingType: visitingType,
                getAnnotationUseCase: getAnnotationUseCase,
                getDocumentationUseCase: getDocumentationUseCase
            )
        }
    }

    private static func inferType(_ code: String) -> TypeName? {
        var code = code
        if code.hasSuffix("{") {
            code = String(code.dropLast())
              .trimmingCharacters(in: .whitespaces)
        }

        return code.inferType
    }
}
