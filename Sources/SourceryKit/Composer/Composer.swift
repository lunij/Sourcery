import Foundation

/// Responsible for composing results of `FileParser`.
public class Composer {
    private var typeMap: [String: Type] = [:]
    private var modules: [String: [String: Type]] = [:]

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
        let resolvedTypealiasMap = composedTypealiases.resolved

        types
            .filter { !$0.isExtension }
            .forEach {
                typeMap[$0.globalName] = $0
                if let module = $0.module {
                    var typesByModules = modules[module, default: [:]]
                    typesByModules[$0.name] = $0
                    modules[module] = typesByModules
                }
            }

        resolveTypes(of: Array(composedTypealiases.unresolved.values), typealiasMap: resolvedTypealiasMap)

        let unifiedTypes = unifyTypes(types, typealiases: resolvedTypealiasMap)

        unifiedTypes.parallelPerform { type in
            type.variables.forEach {
                resolveTypes(of: $0, in: type, typealiases: resolvedTypealiasMap)
            }
            type.methods.forEach {
                resolveTypes(of: $0, in: type, typealiases: resolvedTypealiasMap)
            }
            type.subscripts.forEach {
                resolveTypes(of: $0, in: type, typealiases: resolvedTypealiasMap)
            }

            if let enumeration = type as? Enum {
                resolveTypes(of: enumeration, types: typeMap, typealiases: resolvedTypealiasMap)
            }

            if let composition = type as? ProtocolComposition {
                resolveTypes(of: composition, typealiases: resolvedTypealiasMap)
            }

            if let sourceryProtocol = type as? SourceryProtocol {
                resolveTypes(of: sourceryProtocol, typealiases: resolvedTypealiasMap)
            }
        }

        functions.parallelPerform { function in
            resolveTypes(of: function, in: nil, typealiases: resolvedTypealiasMap)
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
            type.typealiases.forEach { _, alias in
                // maybe just handle non extension case here and extension aliases after resolving them?
                typealiasesByNames[alias.name] = alias
            }
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

    private func resolveTypes(of typealiases: [Typealias], typealiasMap: [String: Typealias]) {
        typealiases.forEach { alias in
            alias.type = resolveType(named: alias.typeName, in: alias.parent, typealiases: typealiasMap)
        }
    }

    private func resolveTypes(of variable: Variable, in type: Type, typealiases: [String: Typealias]) {
        variable.type = resolveType(named: variable.typeName, in: type, typealiases: typealiases)

        if let definedInTypeName = variable.definedInTypeName {
            _ = resolveType(named: definedInTypeName, in: type, typealiases: typealiases)
        }
    }

    private func resolveTypes(of subscript: Subscript, in type: Type, typealiases: [String: Typealias]) {
        `subscript`.parameters.forEach { parameter in
            parameter.type = resolveType(named: parameter.typeName, in: type, typealiases: typealiases)
        }

        `subscript`.returnType = resolveType(named: `subscript`.returnTypeName, in: type, typealiases: typealiases)
        if let definedInTypeName = `subscript`.definedInTypeName {
            _ = resolveType(named: definedInTypeName, in: type, typealiases: typealiases)
        }
    }

    private func resolveTypes(of method: SourceryMethod, in type: Type?, typealiases: [String: Typealias]) {
        method.parameters.forEach { parameter in
            parameter.type = resolveType(named: parameter.typeName, in: type, typealiases: typealiases)
        }

        var definedInType: Type?
        if let definedInTypeName = method.definedInTypeName {
            definedInType = resolveType(named: definedInTypeName, in: type, typealiases: typealiases)
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
            method.returnType = resolveType(named: method.returnTypeName, in: type, typealiases: typealiases)
        }
    }

    private func resolveTypes(of enumeration: Enum, types: [String: Type], typealiases: [String: Typealias]) {
        enumeration.cases.forEach { enumCase in
            enumCase.associatedValues.forEach { associatedValue in
                associatedValue.type = resolveType(named: associatedValue.typeName, in: enumeration, typealiases: typealiases)
            }
        }

        guard enumeration.hasRawType else { return }

        if let rawValueVariable = enumeration.variables.first(where: { $0.name == "rawValue" && !$0.isStatic }) {
            enumeration.rawTypeName = rawValueVariable.actualTypeName
            enumeration.rawType = rawValueVariable.type
        } else if let rawTypeName = enumeration.inheritedTypes.first {
            // enums with no cases or enums with cases that contain associated values can't have raw type
            guard !enumeration.cases.isEmpty,
                  !enumeration.hasAssociatedValues
            else {
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

    private func resolveTypes(of protocolComposition: ProtocolComposition, typealiases: [String: Typealias]) {
        let composedTypes = protocolComposition.composedTypeNames.compactMap { typeName in
            resolveType(named: typeName, in: protocolComposition, typealiases: typealiases)
        }

        protocolComposition.composedTypes = composedTypes
    }

    private func resolveTypes(of sourceryProtocol: SourceryProtocol, typealiases: [String: Typealias]) {
        sourceryProtocol.associatedTypes.forEach { _, value in
            guard let typeName = value.typeName,
                  let type = resolveType(named: typeName, in: sourceryProtocol, typealiases: typealiases)
            else { return }
            value.type = type
        }

        sourceryProtocol.genericRequirements.forEach { requirment in
            if let knownAssociatedType = sourceryProtocol.associatedTypes[requirment.leftType.name] {
                requirment.leftType = knownAssociatedType
            }
            requirment.rightType.type = resolveType(named: requirment.rightType.typeName, in: sourceryProtocol, typealiases: typealiases)
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
                type.implements[globalName] = baseType
            }

            type.basedTypes[globalName] = baseType
        }
    }

    private func resolveType(named typeName: TypeName, in containingType: Type?, typealiases: [String: Typealias]) -> Type? {
        let resolveTypeWithName = { (typeName: TypeName) -> Type? in
            self.resolveType(named: typeName, in: containingType, typealiases: typealiases)
        }

        let unique = typeMap

        if let name = typeName.actualTypeName {
            let resolvedIdentifier = name.generic?.name ?? name.unwrappedTypeName
            return unique[resolvedIdentifier]
        }

        let retrievedName = actualTypeName(for: typeName, containingType: containingType, typealiases: typealiases)
        let lookupName = retrievedName ?? typeName

        if let tuple = lookupName.tuple {
            var needsUpdate = false

            tuple.elements.forEach { tupleElement in
                tupleElement.type = resolveTypeWithName(tupleElement.typeName)
                if tupleElement.typeName.actualTypeName != nil {
                    needsUpdate = true
                }
            }

            if needsUpdate || retrievedName != nil {
                let tupleCopy = TupleType(name: tuple.name, elements: tuple.elements)
                tupleCopy.elements.forEach {
                    $0.typeName = $0.actualTypeName ?? $0.typeName
                    $0.typeName.actualTypeName = nil
                }
                tupleCopy.name = tupleCopy.elements.asTypeName

                typeName.tuple = tupleCopy
                typeName.actualTypeName = TypeName(
                    name: tupleCopy.name,
                    isOptional: typeName.isOptional,
                    isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                    tuple: tupleCopy,
                    array: lookupName.array,
                    dictionary: lookupName.dictionary,
                    closure: lookupName.closure,
                    generic: lookupName.generic
                )
            }
            return nil
        } else if let array = lookupName.array {
            array.elementType = resolveTypeWithName(array.elementTypeName)

            if array.elementTypeName.actualTypeName != nil || retrievedName != nil {
                let array = ArrayType(name: array.name, elementTypeName: array.elementTypeName, elementType: array.elementType)
                array.elementTypeName = array.elementTypeName.actualTypeName ?? array.elementTypeName
                array.elementTypeName.actualTypeName = nil
                array.name = array.asSource
                typeName.array = array
                typeName.generic = array.asGeneric

                typeName.actualTypeName = TypeName(
                    name: array.name,
                    isOptional: typeName.isOptional,
                    isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                    tuple: lookupName.tuple,
                    array: array,
                    dictionary: lookupName.dictionary,
                    closure: lookupName.closure,
                    generic: typeName.generic
                )
            }
        } else if let dictionary = lookupName.dictionary {
            dictionary.keyType = resolveTypeWithName(dictionary.keyTypeName)
            dictionary.valueType = resolveTypeWithName(dictionary.valueTypeName)

            if dictionary.keyTypeName.actualTypeName != nil || dictionary.valueTypeName.actualTypeName != nil || retrievedName != nil {
                let dictionary = DictionaryType(name: dictionary.name, valueTypeName: dictionary.valueTypeName, valueType: dictionary.valueType, keyTypeName: dictionary.keyTypeName, keyType: dictionary.keyType)
                dictionary.keyTypeName = dictionary.keyTypeName.actualTypeName ?? dictionary.keyTypeName
                dictionary.keyTypeName.actualTypeName = nil
                dictionary.valueTypeName = dictionary.valueTypeName.actualTypeName ?? dictionary.valueTypeName
                dictionary.valueTypeName.actualTypeName = nil

                dictionary.name = dictionary.asSource

                typeName.dictionary = dictionary
                typeName.generic = dictionary.asGeneric

                typeName.actualTypeName = TypeName(
                    name: dictionary.asSource,
                    isOptional: typeName.isOptional,
                    isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                    tuple: lookupName.tuple,
                    array: lookupName.array,
                    dictionary: dictionary,
                    closure: lookupName.closure,
                    generic: dictionary.asGeneric
                )
            }
        } else if let closure = lookupName.closure {
            var needsUpdate = false

            closure.returnType = resolveTypeWithName(closure.returnTypeName)
            closure.parameters.forEach { parameter in
                parameter.type = resolveTypeWithName(parameter.typeName)
                if parameter.typeName.actualTypeName != nil {
                    needsUpdate = true
                }
            }

            if closure.returnTypeName.actualTypeName != nil || needsUpdate || retrievedName != nil {
                typeName.closure = closure

                typeName.actualTypeName = TypeName(
                    name: closure.asSource,
                    isOptional: typeName.isOptional,
                    isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                    tuple: lookupName.tuple,
                    array: lookupName.array,
                    dictionary: lookupName.dictionary,
                    closure: closure,
                    generic: lookupName.generic
                )
            }

            return nil
        } else if let generic = lookupName.generic {
            var needsUpdate = false

            generic.typeParameters.forEach { parameter in
                parameter.type = resolveTypeWithName(parameter.typeName)
                if parameter.typeName.actualTypeName != nil {
                    needsUpdate = true
                }
            }

            if needsUpdate || retrievedName != nil {
                let generic = GenericType(name: generic.name, typeParameters: generic.typeParameters)
                generic.typeParameters.forEach {
                    $0.typeName = $0.typeName.actualTypeName ?? $0.typeName
                    $0.typeName.actualTypeName = nil
                }
                typeName.generic = generic
                typeName.array = lookupName.array
                typeName.dictionary = lookupName.dictionary

                let params = generic.typeParameters.map(\.typeName.asSource).joined(separator: ", ")

                typeName.actualTypeName = TypeName(
                    name: "\(generic.name)<\(params)>",
                    isOptional: typeName.isOptional,
                    isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                    tuple: lookupName.tuple,
                    array: lookupName.array,
                    dictionary: lookupName.dictionary,
                    closure: lookupName.closure,
                    generic: generic
                )
            }
        }

        if let aliasedName = (typeName.actualTypeName ?? retrievedName), aliasedName.unwrappedTypeName != typeName.unwrappedTypeName {
            typeName.actualTypeName = aliasedName
        }

        let finalLookup = typeName.actualTypeName ?? typeName
        let resolvedIdentifier = finalLookup.generic?.name ?? finalLookup.unwrappedTypeName

        // should we cache resolved typenames?
        return unique[resolvedIdentifier]
    }

    private func actualTypeName(for typeName: TypeName, containingType: Type? = nil, typealiases: [String: Typealias]) -> TypeName? {
        let unique = typeMap

        var unwrapped = typeName.unwrappedTypeName
        if let generic = typeName.generic {
            unwrapped = generic.name
        }

        guard let aliased = resolveGlobalName(for: unwrapped, containingType: containingType, unique: unique, modules: modules, typealiases: typealiases) else {
            return nil
        }

        let generic = typeName.generic.map { GenericType(name: $0.name, typeParameters: $0.typeParameters) }
        generic?.name = aliased.name
        let dictionary = typeName.dictionary.map { DictionaryType(name: $0.name, valueTypeName: $0.valueTypeName, valueType: $0.valueType, keyTypeName: $0.keyTypeName, keyType: $0.keyType) }
        dictionary?.name = aliased.name
        let array = typeName.array.map { ArrayType(name: $0.name, elementTypeName: $0.elementTypeName, elementType: $0.elementType) }
        array?.name = aliased.name

        return TypeName(
            name: aliased.name,
            isOptional: typeName.isOptional,
            isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
            tuple: aliased.typealias?.typeName.tuple ?? typeName.tuple,
            array: aliased.typealias?.typeName.array ?? array,
            dictionary: aliased.typealias?.typeName.dictionary ?? dictionary,
            closure: aliased.typealias?.typeName.closure ?? typeName.closure,
            generic: aliased.typealias?.typeName.generic ?? generic
        )
    }

    /// Resolves type identifier for name
    private func resolveGlobalName(
        for type: String,
        containingType: Type? = nil,
        unique: [String: Type]? = nil,
        modules: [String: [String: Type]],
        typealiases: [String: Typealias]
    ) -> (name: String, typealias: Typealias?)? {
        // if the type exists for this name and isn't an extension just return it's name
        // if it's extension we need to check if there aren't other options
        if let realType = unique?[type], realType.isExtension == false {
            return (name: realType.globalName, typealias: nil)
        }

        if let alias = typealiases[type] {
            return (name: alias.type?.globalName ?? alias.typeName.name, typealias: alias)
        }

        if let containingType {
            if type == "Self" {
                return (name: containingType.globalName, typealias: nil)
            }

            var currentContainer: Type? = containingType
            while currentContainer != nil, let parentName = currentContainer?.globalName {
                /// manually walk the containment tree
                if let name = resolveGlobalName(for: "\(parentName).\(type)", containingType: nil, unique: unique, modules: modules, typealiases: typealiases) {
                    return name
                }

                currentContainer = currentContainer?.parent
            }
        }

        if let inferred = inferTypeNameFromModules(from: type, containedInType: containingType, uniqueTypes: unique ?? [:], modules: modules) {
            return (name: inferred, typealias: nil)
        }

        return typeFromComposedName(type, modules: modules).map { (name: $0.globalName, typealias: nil) }
    }

    private func inferTypeNameFromModules(from typeIdentifier: String, containedInType: Type?, uniqueTypes: [String: Type], modules: [String: [String: Type]]) -> String? {
        func fullName(for module: String) -> String {
            "\(module).\(typeIdentifier)"
        }

        func type(for module: String) -> Type? {
            modules[module]?[typeIdentifier]
        }

        func ambiguousErrorMessage(from types: [Type]) -> String? {
            logger.astWarning("Ambiguous type \(typeIdentifier), found \(types.map(\.globalName).joined(separator: ", ")). Specify module name at declaration site to disambiguate.")
            return nil
        }

        let explicitModulesAtDeclarationSite: [String] = [
            containedInType?.module.map { [$0] } ?? [], // main module for this typename
            containedInType?.imports.map(\.moduleName) ?? [] // imported modules
        ]
        .flatMap { $0 }

        let remainingModules = Set(modules.keys).subtracting(explicitModulesAtDeclarationSite)

        /// We need to check whether we can find type in one of the modules but we need to be careful to avoid amibiguity
        /// First checking explicit modules available at declaration site (so source module + all imported ones)
        /// If there is no ambigiuity there we can assume that module will be resolved by the compiler
        /// If that's not the case we look after remaining modules in the application and if the typename has no ambigiuity we use that
        /// But if there is more than 1 typename duplication across modules we have no way to resolve what is the compiler going to use so we fail
        let moduleSetsToCheck: [[String]] = [
            explicitModulesAtDeclarationSite,
            Array(remainingModules)
        ]

        for modules in moduleSetsToCheck {
            let possibleTypes = modules
                .compactMap { type(for: $0) }

            if possibleTypes.count > 1 {
                return ambiguousErrorMessage(from: possibleTypes)
            }

            if let type = possibleTypes.first {
                return type.globalName
            }
        }

        // as last result for unknown types / extensions
        // try extracting type from unique array
        if let module = containedInType?.module {
            return uniqueTypes[fullName(for: module)]?.globalName
        }
        return nil
    }

    private func typeFromComposedName(_ name: String, modules: [String: [String: Type]]) -> Type? {
        guard name.contains(".") else { return nil }
        let nameComponents = name.components(separatedBy: ".")
        let moduleName = nameComponents[0]
        let typeName = nameComponents.suffix(from: 1).joined(separator: ".")
        return modules[moduleName]?[typeName]
    }

    private func resolveExtensionOfNestedType(_ type: Type) {
        var components = type.localName.components(separatedBy: ".")
        let rootName = type.module ?? components.removeFirst() // Module/parent name
        if let moduleTypes = modules[rootName], let baseType = moduleTypes[components.joined(separator: ".")] ?? moduleTypes[type.localName] {
            type.localName = baseType.localName
            type.module = baseType.module
            type.parent = baseType.parent
        } else {
            for _import in type.imports {
                let parentKey = "\(rootName).\(components.joined(separator: "."))"
                let parentKeyFull = "\(_import.moduleName).\(parentKey)"
                if let moduleTypes = modules[_import.moduleName], let baseType = moduleTypes[parentKey] ?? moduleTypes[parentKeyFull] {
                    type.localName = baseType.localName
                    type.module = baseType.module
                    type.parent = baseType.parent
                    return
                }
            }
        }
    }

    private func unifyTypes(_ types: [Type], typealiases: [String: Typealias]) -> [Type] {
        /// Resolve actual names of extensions, as they could have been done on typealias and note updated child names in uniques if needed
        types
            .filter(\.isExtension)
            .forEach {
                let oldName = $0.globalName

                if $0.parent == nil, $0.localName.contains(".") {
                    resolveExtensionOfNestedType($0)
                }

                if let resolved = resolveGlobalName(for: oldName, containingType: $0.parent, unique: typeMap, modules: modules, typealiases: typealiases)?.name {
                    $0.localName = resolved.replacingOccurrences(of: "\($0.module != nil ? "\($0.module!)." : "")", with: "")
                } else {
                    return
                }

                // nothing left to do
                guard oldName != $0.globalName else {
                    return
                }

                // if it had contained types, they might have been fully defined and so their name has to be noted in uniques
                func rewriteChildren(of type: Type) {
                    // child is never an extension so no need to check
                    for child in type.containedTypes {
                        typeMap[child.globalName] = child
                        rewriteChildren(of: child)
                    }
                }
                rewriteChildren(of: $0)
            }

        // extend all types with their extensions
        types.forEach { type in
            type.inheritedTypes = type.inheritedTypes.map { inheritedName in
                resolveGlobalName(for: inheritedName, containingType: type.parent, unique: typeMap, modules: modules, typealiases: typealiases)?.name ?? inheritedName
            }

            let uniqueType = typeMap[type.globalName] ?? // this check will only fail on an extension?
                typeFromComposedName(type.name, modules: modules) ?? // this can happen for an extension on unknown type, this case should probably be handled by the inferTypeNameFromModules
                (inferTypeNameFromModules(from: type.localName, containedInType: type.parent, uniqueTypes: typeMap, modules: modules).flatMap { typeMap[$0] })

            guard let current = uniqueType else {
                assert(type.isExtension, "Type \(type.globalName) should be extension")

                // for unknown types we still store their extensions but mark them as unknown
                type.isUnknownExtension = true
                if let existingType = typeMap[type.globalName] {
                    existingType.extend(type)
                    typeMap[type.globalName] = existingType
                } else {
                    typeMap[type.globalName] = type
                }

                let inheritanceClause = type.inheritedTypes.isEmpty ? "" :
                    ": \(type.inheritedTypes.joined(separator: ", "))"

                logger.astWarning("Found \"extension \(type.name)\(inheritanceClause)\" of type for which there is no original type declaration information.")
                return
            }

            if current == type { return }

            current.extend(type)
            typeMap[current.globalName] = current
        }

        let values = typeMap.values
        var processed = Set<String>(minimumCapacity: values.count)
        return typeMap.values.filter {
            let name = $0.globalName
            let wasProcessed = processed.contains(name)
            processed.insert(name)
            return !wasProcessed
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
