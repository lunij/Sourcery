import Foundation
import SwiftSyntax

extension SourceryMethod {
    convenience init(
        _ node: FunctionDeclSyntax,
        parent: Type?,
        typeName: TypeName?,
        getAnnotationUseCase: GetAnnotationUseCase
    ) {
        self.init(
            node: node,
            parent: parent,
            identifier: node.name.text.trimmed,
            typeName: typeName,
            signature: Signature(node.signature, getAnnotationUseCase: getAnnotationUseCase),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            getAnnotationUseCase: getAnnotationUseCase
        )
    }

    convenience init(
        _ node: InitializerDeclSyntax,
        parent: Type,
        typeName: TypeName,
        getAnnotationUseCase: GetAnnotationUseCase
    ) {
        let signature = node.signature
        self.init(
            node: node,
            parent: parent,
            identifier: "init\(node.optionalMark?.text.trimmed ?? "")",
            typeName: typeName,
            signature: Signature(
                parameters: signature.parameterClause.parameters,
                output: nil,
                asyncKeyword: nil,
                throwsOrRethrowsKeyword: signature.effectSpecifiers?.throwsSpecifier?.description.trimmed,
                getAnnotationUseCase: getAnnotationUseCase
            ),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            getAnnotationUseCase: getAnnotationUseCase
        )
    }

    convenience init(
        _ node: DeinitializerDeclSyntax,
        parent: Type,
        typeName: TypeName,
        getAnnotationUseCase: GetAnnotationUseCase
    ) {
        self.init(
            node: node,
            parent: parent,
            identifier: "deinit",
            typeName: typeName,
            signature: Signature(
                parameters: nil,
                output: nil,
                asyncKeyword: nil,
                throwsOrRethrowsKeyword: nil,
                getAnnotationUseCase: getAnnotationUseCase
            ),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: nil,
            genericWhereClause: nil,
            getAnnotationUseCase: getAnnotationUseCase
        )
    }

    convenience init(
      node: DeclSyntaxProtocol,
      parent: Type?,
      identifier: String,
      typeName: TypeName?,
      signature: Signature,
      modifiers: DeclModifierListSyntax?,
      attributes: AttributeListSyntax?,
      genericParameterClause: GenericParameterClauseSyntax?,
      genericWhereClause: GenericWhereClauseSyntax?,
      getAnnotationUseCase: GetAnnotationUseCase
    ) {
        let initializerNode = node as? InitializerDeclSyntax

        let modifiers = modifiers?.map(Modifier.init) ?? []
        let baseModifiers = modifiers.baseModifiers(parent: parent)

        var returnTypeName: TypeName
        if let initializer = initializerNode, let typeName = typeName {
            if let optional = initializer.optionalMark {
                returnTypeName = TypeName(name: typeName.name + optional.text.trimmed)
            } else {
                returnTypeName = typeName
            }
        } else {
            returnTypeName = signature.output ?? TypeName(name: "Void")
        }

        let funcName = identifier.last == "?" ? String(identifier.dropLast()) : identifier
        var fullName = identifier
        if let generics = genericParameterClause?.parameters {
            fullName = funcName + "<\(generics.description.trimmed)>"
        }

        if let genericWhereClause = genericWhereClause {
            // TODO: add generic requirement to method
            // TODO: TBR
            returnTypeName = TypeName(name: returnTypeName.name + " \(genericWhereClause.trimmedDescription)",
                                      unwrappedTypeName: returnTypeName.unwrappedTypeName,
                                      attributes: returnTypeName.attributes,
                                      isOptional: returnTypeName.isOptional,
                                      isImplicitlyUnwrappedOptional: returnTypeName.isImplicitlyUnwrappedOptional,
                                      tuple: returnTypeName.tuple,
                                      array: returnTypeName.array,
                                      dictionary: returnTypeName.dictionary,
                                      closure: returnTypeName.closure,
                                      generic: returnTypeName.generic
            )
        }

        let name = signature.definition(with: fullName)
        let selectorName = signature.selector(with: funcName)

        let annotations: Annotations
        let documentation: Documentation
        if let function = node as? FunctionDeclSyntax {
            annotations = getAnnotationUseCase.annotations(from: function)
            documentation = getAnnotationUseCase.documentation(from: function)
        } else {
            annotations = getAnnotationUseCase.annotations(fromToken: node)
            documentation = getAnnotationUseCase.documentation(fromToken: node)
        }

        self.init(
          name: name,
          selectorName: selectorName,
          parameters: signature.input,
          returnTypeName: returnTypeName,
          isAsync: signature.asyncKeyword == "async",
          throws: signature.throwsOrRethrowsKeyword == "throws",
          rethrows: signature.throwsOrRethrowsKeyword == "rethrows",
          accessLevel: baseModifiers.readAccess,
          isStatic: initializerNode != nil ? true : baseModifiers.isStatic,
          isClass: baseModifiers.isClass,
          isFailableInitializer: initializerNode?.optionalMark != nil,
          attributes: .init(from: attributes),
          modifiers: modifiers,
          annotations: annotations,
          documentation: documentation,
          definedInTypeName: typeName
        )
    }

}
