import Foundation
import SwiftSyntax

extension Function {
    convenience init(
        _ node: FunctionDeclSyntax,
        parent: Type?,
        typeName: TypeName?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        self.init(
            node: node,
            parent: parent,
            identifier: node.name.text.trimmed,
            typeName: typeName,
            signature: FunctionSignature(node.signature, getAnnotationUseCase: getAnnotationUseCase),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            getAnnotationUseCase: getAnnotationUseCase,
            getDocumentationUseCase: getDocumentationUseCase
        )
    }

    convenience init(
        _ node: InitializerDeclSyntax,
        parent: Type,
        typeName: TypeName,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        self.init(
            node: node,
            parent: parent,
            identifier: "init\(node.optionalMark?.text.trimmed ?? "")",
            typeName: typeName,
            signature: FunctionSignature(node.signature, getAnnotationUseCase: getAnnotationUseCase),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            getAnnotationUseCase: getAnnotationUseCase,
            getDocumentationUseCase: getDocumentationUseCase
        )
    }

    convenience init(
        _ node: DeinitializerDeclSyntax,
        parent: Type,
        typeName: TypeName,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        self.init(
            node: node,
            parent: parent,
            identifier: "deinit",
            typeName: typeName,
            signature: FunctionSignature(parameters: []),
            modifiers: node.modifiers,
            attributes: node.attributes,
            genericParameterClause: nil,
            genericWhereClause: nil,
            getAnnotationUseCase: getAnnotationUseCase,
            getDocumentationUseCase: getDocumentationUseCase
        )
    }

    convenience init(
        node: DeclSyntaxProtocol,
        parent: Type?,
        identifier: String,
        typeName: TypeName?,
        signature: FunctionSignature,
        modifiers: DeclModifierListSyntax?,
        attributes: AttributeListSyntax?,
        genericParameterClause: GenericParameterClauseSyntax?,
        genericWhereClause: GenericWhereClauseSyntax?,
        getAnnotationUseCase: GetAnnotationUseCase,
        getDocumentationUseCase: GetDocumentationUseCase?
    ) {
        let initializerNode = node as? InitializerDeclSyntax

        let modifiers = modifiers?.map(Modifier.init) ?? []
        let baseModifiers = modifiers.baseModifiers(parent: parent)

        var returnTypeName: TypeName = if let initializer = initializerNode, let typeName {
            if let optional = initializer.optionalMark {
                TypeName(name: typeName.name + optional.text.trimmed)
            } else {
                typeName
            }
        } else {
            signature.returnType ?? TypeName(name: "Void")
        }

        let funcName = identifier.last == "?" ? String(identifier.dropLast()) : identifier
        var fullName = identifier
        if let generics = genericParameterClause?.parameters {
            fullName = funcName + "<\(generics.description.trimmed)>"
        }

        if let genericWhereClause {
            // TODO: add generic requirement to method
            // TODO: TBR
            returnTypeName = TypeName(
                name: returnTypeName.name + " \(genericWhereClause.trimmedDescription)",
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
            annotations = getAnnotationUseCase.parseAnnotations(from: function)
            documentation = getDocumentationUseCase?.documentation(from: function) ?? []
        } else {
            annotations = getAnnotationUseCase.parseAnnotations(from: node)
            documentation = getDocumentationUseCase?.documentation(from: node) ?? []
        }

        self.init(
            name: name,
            selectorName: selectorName,
            parameters: signature.parameters,
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
