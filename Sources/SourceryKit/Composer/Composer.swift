import Foundation

/// Responsible for composing results of `FileParser`.
public struct Composer {

    public init() {}

    /// Performs final processing of discovered types:
    /// - extends types with their corresponding extensions;
    /// - replaces typealiases with actual types
    /// - finds actual types for variables and enums raw values
    /// - filters out any private types and extensions
    ///
    /// - Parameter parserResult: Result of parsing source code.
    /// - Returns: Final types and extensions of unknown types.
    public func uniqueTypesAndFunctions(
        functions: [SourceryMethod],
        typealiases: [Typealias],
        types: [Type]
    ) -> (types: [Type], functions: [SourceryMethod], typealiases: [Typealias]) {
        types.forEach { $0.setMembersDefinedInType() }

        let composedTypealiases = composeTypealiases(typealiases, types: types)
        let composed = ParserResultsComposed(types: types, composedTypealiases: composedTypealiases)
        let unifiedTypes = composed.unifiedTypes()

        let resolveType = { (typeName: TypeName, containingType: Type?) -> Type? in
            return composed.resolveType(typeName: typeName, containingType: containingType)
        }

        unifiedTypes.parallelPerform { type in
            type.variables.forEach {
                resolveVariableTypes($0, of: type, resolve: resolveType)
            }
            type.methods.forEach {
                resolveMethodTypes($0, of: type, resolve: resolveType)
            }
            type.subscripts.forEach {
                resolveSubscriptTypes($0, of: type, resolve: resolveType)
            }

            if let enumeration = type as? Enum {
                resolveEnumTypes(enumeration, types: composed.typeMap, resolve: resolveType)
            }

            if let composition = type as? ProtocolComposition {
                resolveProtocolCompositionTypes(composition, resolve: resolveType)
            }

            if let sourceryProtocol = type as? SourceryProtocol {
                resolveProtocolTypes(sourceryProtocol, resolve: resolveType)
            }
        }

        functions.parallelPerform { function in
            resolveMethodTypes(function, of: nil, resolve: resolveType)
        }

        updateTypeRelationships(types: unifiedTypes)

        return (
            types: unifiedTypes.sorted { $0.globalName < $1.globalName },
            functions: functions.sorted { $0.name < $1.name },
            typealiases: composedTypealiases.unresolved.values.sorted { $0.name < $1.name }
        )
    }

    struct ComposedTypealiases {
        let resolved: [String: Typealias]
        let unresolved: [String: Typealias]
    }

    /// returns typealiases map to their full names, with `resolved` removing intermediate
    /// typealises and `unresolved` including typealiases that reference other typealiases.
    private func composeTypealiases(_ typealiases: [Typealias], types: [Type]) -> ComposedTypealiases {
        // For any resolution we need to be looking at accessLevel and module boundaries
        // e.g. there might be a typealias `private typealias Something = MyType` in one module and same name in another with public modifier, one could be accessed and the other could not
        var typealiasesByNames = [String: Typealias]()
        typealiases.forEach { typealiasesByNames[$0.name] = $0 }
        types.forEach { type in
            type.typealiases.forEach({ (_, alias) in
                // TODO: should I deal with the fact that alias.name depends on type name but typenames might be updated later on
                // maybe just handle non extension case here and extension aliases after resolving them?
                typealiasesByNames[alias.name] = alias
            })
        }

        let unresolved = typealiasesByNames

        // ! if a typealias leads to another typealias, follow through and replace with final type
        typealiasesByNames.forEach { _, alias in
            var aliasNamesToReplace = [alias.name]
            var finalAlias = alias
            while let targetAlias = typealiasesByNames[finalAlias.typeName.name] {
                aliasNamesToReplace.append(targetAlias.name)
                finalAlias = targetAlias
            }

            // ! replace all keys
            aliasNamesToReplace.forEach { typealiasesByNames[$0] = finalAlias }
        }

        return ComposedTypealiases(resolved: typealiasesByNames, unresolved: unresolved)
    }

    typealias TypeResolver = (TypeName, Type?) -> Type?

    private func resolveVariableTypes(_ variable: Variable, of type: Type, resolve: TypeResolver) {
        variable.type = resolve(variable.typeName, type)

        /// The actual `definedInType` is assigned in `uniqueTypes` but we still
        /// need to resolve the type to correctly parse typealiases
        /// @see https://github.com/krzysztofzablocki/Sourcery/pull/374
        if let definedInTypeName = variable.definedInTypeName {
            _ = resolve(definedInTypeName, type)
        }
    }

    private func resolveSubscriptTypes(_ subscript: Subscript, of type: Type, resolve: TypeResolver) {
        `subscript`.parameters.forEach { (parameter) in
            parameter.type = resolve(parameter.typeName, type)
        }

        `subscript`.returnType = resolve(`subscript`.returnTypeName, type)
        if let definedInTypeName = `subscript`.definedInTypeName {
            _ = resolve(definedInTypeName, type)
        }
    }

    private func resolveMethodTypes(_ method: SourceryMethod, of type: Type?, resolve: TypeResolver) {
        method.parameters.forEach { parameter in
            parameter.type = resolve(parameter.typeName, type)
        }

        /// The actual `definedInType` is assigned in `uniqueTypes` but we still
        /// need to resolve the type to correctly parse typealiases
        /// @see https://github.com/krzysztofzablocki/Sourcery/pull/374
        var definedInType: Type?
        if let definedInTypeName = method.definedInTypeName {
            definedInType = resolve(definedInTypeName, type)
        }

        guard !method.returnTypeName.isVoid else { return }

        if method.isInitializer || method.isFailableInitializer {
            method.returnType = definedInType
            if let type = method.actualDefinedInTypeName {
                if method.isFailableInitializer {
                    method.returnTypeName = TypeName(
                        name: type.name,
                        isOptional: true,
                        isImplicitlyUnwrappedOptional: false,
                        tuple: type.tuple,
                        array: type.array,
                        dictionary: type.dictionary,
                        closure: type.closure,
                        generic: type.generic,
                        isProtocolComposition: type.isProtocolComposition
                    )
                } else if method.isInitializer {
                    method.returnTypeName = type
                }
            }
        } else {
            method.returnType = resolve(method.returnTypeName, type)
        }
    }

    private func resolveEnumTypes(_ enumeration: Enum, types: [String: Type], resolve: TypeResolver) {
        enumeration.cases.forEach { enumCase in
            enumCase.associatedValues.forEach { associatedValue in
                associatedValue.type = resolve(associatedValue.typeName, enumeration)
            }
        }

        guard enumeration.hasRawType else { return }

        if let rawValueVariable = enumeration.variables.first(where: { $0.name == "rawValue" && !$0.isStatic }) {
            enumeration.rawTypeName = rawValueVariable.actualTypeName
            enumeration.rawType = rawValueVariable.type
        } else if let rawTypeName = enumeration.inheritedTypes.first {
            // enums with no cases or enums with cases that contain associated values can't have raw type
            guard !enumeration.cases.isEmpty,
                  !enumeration.hasAssociatedValues else {
                return enumeration.rawTypeName = nil
            }

            if let rawTypeCandidate = types[rawTypeName] {
                if !((rawTypeCandidate is SourceryProtocol) || (rawTypeCandidate is ProtocolComposition)) {
                    enumeration.rawTypeName = TypeName(rawTypeName)
                    enumeration.rawType = rawTypeCandidate
                }
            } else {
                enumeration.rawTypeName = TypeName(rawTypeName)
            }
        }
    }

    private func resolveProtocolCompositionTypes(_ protocolComposition: ProtocolComposition, resolve: TypeResolver) {
        let composedTypes = protocolComposition.composedTypeNames.compactMap { typeName in
            resolve(typeName, protocolComposition)
        }

        protocolComposition.composedTypes = composedTypes
    }

    private func resolveProtocolTypes(_ sourceryProtocol: SourceryProtocol, resolve: TypeResolver) {
        sourceryProtocol.associatedTypes.forEach { (_, value) in
            guard let typeName = value.typeName,
                  let type = resolve(typeName, sourceryProtocol)
            else { return }
            value.type = type
        }

        sourceryProtocol.genericRequirements.forEach { requirment in
            if let knownAssociatedType = sourceryProtocol.associatedTypes[requirment.leftType.name] {
                requirment.leftType = knownAssociatedType
            }
            requirment.rightType.type = resolve(requirment.rightType.typeName, sourceryProtocol)
        }
    }

    private func updateTypeRelationships(types: [Type]) {
        var typesByName = [String: Type]()
        types.forEach { typesByName[$0.globalName] = $0 }

        var processed = [String: Bool]()
        types.forEach { type in
            if let type = type as? Class, let supertype = type.inheritedTypes.first.flatMap({ typesByName[$0] }) as? Class {
                type.supertype = supertype
            }
            processed[type.globalName] = true
            updateTypeRelationship(for: type, typesByName: typesByName, processed: &processed)
        }
    }

    private func findBaseType(for type: Type, name: String, typesByName: [String: Type]) -> Type? {
        if let baseType = typesByName[name] {
            return baseType
        }
        if let module = type.module, let baseType = typesByName["\(module).\(name)"] {
            return baseType
        }
        for importModule in type.imports {
            if let baseType = typesByName["\(importModule).\(name)"] {
                return baseType
            }
        }
        return nil
    }

    private func updateTypeRelationship(for type: Type, typesByName: [String: Type], processed: inout [String: Bool]) {
        type.based.keys.forEach { name in
            guard let baseType = findBaseType(for: type, name: name, typesByName: typesByName) else { return }
            let globalName = baseType.globalName
            if processed[globalName] != true {
                processed[globalName] = true
                updateTypeRelationship(for: baseType, typesByName: typesByName, processed: &processed)
            }

            baseType.based.keys.forEach { type.based[$0] = $0 }
            baseType.basedTypes.forEach { type.basedTypes[$0.key] = $0.value }
            baseType.inherits.forEach { type.inherits[$0.key] = $0.value }
            baseType.implements.forEach { type.implements[$0.key] = $0.value }

            if baseType is Class {
                type.inherits[globalName] = baseType
            } else if let baseProtocol = baseType as? SourceryProtocol {
                type.implements[globalName] = baseProtocol
                if let extendingProtocol = type as? SourceryProtocol {
                    baseProtocol.associatedTypes.forEach {
                        if extendingProtocol.associatedTypes[$0.key] == nil {
                            extendingProtocol.associatedTypes[$0.key] = $0.value
                        }
                    }
                }
            } else if baseType is ProtocolComposition {
                // TODO: associated types?
                type.implements[globalName] = baseType
            }

            type.basedTypes[globalName] = baseType
        }
    }
}

private extension Type {
    func setMembersDefinedInType() {
        variables.forEach { $0.definedInType = self }
        methods.forEach { $0.definedInType = self }
        subscripts.forEach { $0.definedInType = self }
    }
}
