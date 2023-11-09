import Foundation

internal class ParserResultsComposed {
    private(set) var typeMap = [String: Type]()
    private(set) var modules = [String: [String: Type]]()

    private let parsedTypes: [Type]
    private let resolvedTypealiases: [String: Typealias]
    private let unresolvedTypealiases: [String: Typealias]

    init(
        types: [Type],
        composedTypealiases: Composer.ComposedTypealiases
    ) {
        resolvedTypealiases = composedTypealiases.resolved
        unresolvedTypealiases = composedTypealiases.unresolved
        parsedTypes = types

        // map all known types to their names
        parsedTypes
            .filter { !$0.isExtension }
            .forEach {
                typeMap[$0.globalName] = $0
                if let module = $0.module {
                    var typesByModules = modules[module, default: [:]]
                    typesByModules[$0.name] = $0
                    modules[module] = typesByModules
                }
            }

        /// Resolve typealiases
        let typealiases = Array(unresolvedTypealiases.values)
        typealiases.forEach { alias in
            alias.type = resolveType(typeName: alias.typeName, containingType: alias.parent)
        }
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

    func unifiedTypes() -> [Type] {
        /// Resolve actual names of extensions, as they could have been done on typealias and note updated child names in uniques if needed
        parsedTypes
            .filter { $0.isExtension }
            .forEach {
                let oldName = $0.globalName

                if $0.parent == nil, $0.localName.contains(".") {
                    resolveExtensionOfNestedType($0)
                }

                if let resolved = resolveGlobalName(for: oldName, containingType: $0.parent, unique: typeMap, modules: modules, typealiases: resolvedTypealiases)?.name {
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
        parsedTypes.forEach { type in
            type.inheritedTypes = type.inheritedTypes.map { inheritedName in
                resolveGlobalName(for: inheritedName, containingType: type.parent, unique: typeMap, modules: modules, typealiases: resolvedTypealiases)?.name ?? inheritedName
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
        return typeMap.values.filter({
            let name = $0.globalName
            let wasProcessed = processed.contains(name)
            processed.insert(name)
            return !wasProcessed
        })
    }

    /// Resolves type identifier for name
    func resolveGlobalName(for type: String,
                           containingType: Type? = nil,
                           unique: [String: Type]? = nil,
                           modules: [String: [String: Type]],
                           typealiases: [String: Typealias]) -> (name: String, typealias: Typealias?)? {
        // if the type exists for this name and isn't an extension just return it's name
        // if it's extension we need to check if there aren't other options TODO: verify
        if let realType = unique?[type], realType.isExtension == false {
            return (name: realType.globalName, typealias: nil)
        }

        if let alias = typealiases[type] {
            return (name: alias.type?.globalName ?? alias.typeName.name, typealias: alias)
        }

        if let containingType = containingType {
            if type == "Self" {
                return (name: containingType.globalName, typealias: nil)
            }

            var currentContainer: Type? = containingType
            while currentContainer != nil, let parentName = currentContainer?.globalName {
                /// TODO: no parent for sure?
                /// manually walk the containment tree
                if let name = resolveGlobalName(for: "\(parentName).\(type)", containingType: nil, unique: unique, modules: modules, typealiases: typealiases) {
                    return name
                }

                currentContainer = currentContainer?.parent
            }

//            if let name = resolveGlobalName(for: "\(containingType.globalName).\(type)", containingType: containingType.parent, unique: unique, modules: modules, typealiases: typealiases) {
//                return name
//            }

//             last check it's via module
//            if let module = containingType.module, let name = resolveGlobalName(for: "\(module).\(type)", containingType: nil, unique: unique, modules: modules, typealiases: typealiases) {
//                return name
//            }
        }

        // TODO: is this needed?
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
            return modules[module]?[typeIdentifier]
        }

        func ambiguousErrorMessage(from types: [Type]) -> String? {
            logger.astWarning("Ambiguous type \(typeIdentifier), found \(types.map { $0.globalName }.joined(separator: ", ")). Specify module name at declaration site to disambiguate.")
            return nil
        }

        let explicitModulesAtDeclarationSite: [String] = [
            containedInType?.module.map { [$0] } ?? [],    // main module for this typename
            containedInType?.imports.map { $0.moduleName } ?? []    // imported modules
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

    func typeFromComposedName(_ name: String, modules: [String: [String: Type]]) -> Type? {
        guard name.contains(".") else { return nil }
        let nameComponents = name.components(separatedBy: ".")
        let moduleName = nameComponents[0]
        let typeName = nameComponents.suffix(from: 1).joined(separator: ".")
        return modules[moduleName]?[typeName]
    }

    func resolveType(typeName: TypeName, containingType: Type?) -> Type? {
        let resolveTypeWithName = { (typeName: TypeName) -> Type? in
            return self.resolveType(typeName: typeName, containingType: containingType)
        }

        let unique = typeMap

        if let name = typeName.actualTypeName {
            let resolvedIdentifier = name.generic?.name ?? name.unwrappedTypeName
            return unique[resolvedIdentifier]
        }

        let retrievedName = actualTypeName(for: typeName, containingType: containingType)
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

                typeName.tuple = tupleCopy // TODO: really don't like this old behaviour
                typeName.actualTypeName = TypeName(name: tupleCopy.name,
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
        } else
        if let array = lookupName.array {
            array.elementType = resolveTypeWithName(array.elementTypeName)

            if array.elementTypeName.actualTypeName != nil || retrievedName != nil {
                let array = ArrayType(name: array.name, elementTypeName: array.elementTypeName, elementType: array.elementType)
                array.elementTypeName = array.elementTypeName.actualTypeName ?? array.elementTypeName
                array.elementTypeName.actualTypeName = nil
                array.name = array.asSource
                typeName.array = array // TODO: really don't like this old behaviour
                typeName.generic = array.asGeneric // TODO: really don't like this old behaviour

                typeName.actualTypeName = TypeName(name: array.name,
                                                   isOptional: typeName.isOptional,
                                                   isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                                                   tuple: lookupName.tuple,
                                                   array: array,
                                                   dictionary: lookupName.dictionary,
                                                   closure: lookupName.closure,
                                                   generic: typeName.generic
                )
            }
        } else
        if let dictionary = lookupName.dictionary {
            dictionary.keyType = resolveTypeWithName(dictionary.keyTypeName)
            dictionary.valueType = resolveTypeWithName(dictionary.valueTypeName)

            if dictionary.keyTypeName.actualTypeName != nil || dictionary.valueTypeName.actualTypeName != nil || retrievedName != nil {
                let dictionary = DictionaryType(name: dictionary.name, valueTypeName: dictionary.valueTypeName, valueType: dictionary.valueType, keyTypeName: dictionary.keyTypeName, keyType: dictionary.keyType)
                dictionary.keyTypeName = dictionary.keyTypeName.actualTypeName ?? dictionary.keyTypeName
                dictionary.keyTypeName.actualTypeName = nil // TODO: really don't like this old behaviour
                dictionary.valueTypeName = dictionary.valueTypeName.actualTypeName ?? dictionary.valueTypeName
                dictionary.valueTypeName.actualTypeName = nil // TODO: really don't like this old behaviour

                dictionary.name = dictionary.asSource

                typeName.dictionary = dictionary // TODO: really don't like this old behaviour
                typeName.generic = dictionary.asGeneric // TODO: really don't like this old behaviour

                typeName.actualTypeName = TypeName(name: dictionary.asSource,
                                                   isOptional: typeName.isOptional,
                                                   isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                                                   tuple: lookupName.tuple,
                                                   array: lookupName.array,
                                                   dictionary: dictionary,
                                                   closure: lookupName.closure,
                                                   generic: dictionary.asGeneric
                )
            }
        } else
        if let closure = lookupName.closure {
            var needsUpdate = false

            closure.returnType = resolveTypeWithName(closure.returnTypeName)
            closure.parameters.forEach { parameter in
                parameter.type = resolveTypeWithName(parameter.typeName)
                if parameter.typeName.actualTypeName != nil {
                    needsUpdate = true
                }
            }

            if closure.returnTypeName.actualTypeName != nil || needsUpdate || retrievedName != nil {
                typeName.closure = closure // TODO: really don't like this old behaviour

                typeName.actualTypeName = TypeName(name: closure.asSource,
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
        } else
        if let generic = lookupName.generic {
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
                    $0.typeName.actualTypeName = nil // TODO: really don't like this old behaviour
                }
                typeName.generic = generic // TODO: really don't like this old behaviour
                typeName.array = lookupName.array // TODO: really don't like this old behaviour
                typeName.dictionary = lookupName.dictionary // TODO: really don't like this old behaviour

                let params = generic.typeParameters.map { $0.typeName.asSource }.joined(separator: ", ")

                typeName.actualTypeName = TypeName(name: "\(generic.name)<\(params)>",
                                                   isOptional: typeName.isOptional,
                                                   isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                                                   tuple: lookupName.tuple,
                                                   array: lookupName.array, // TODO: asArray
                                                   dictionary: lookupName.dictionary, // TODO: asDictionary
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

    private func actualTypeName(for typeName: TypeName,
                                       containingType: Type? = nil) -> TypeName? {
        let unique = typeMap
        let typealiases = resolvedTypealiases

        var unwrapped = typeName.unwrappedTypeName
        if let generic = typeName.generic {
            unwrapped = generic.name
        }

        guard let aliased = resolveGlobalName(for: unwrapped, containingType: containingType, unique: unique, modules: modules, typealiases: typealiases) else {
            return nil
        }

        /// TODO: verify
        let generic = typeName.generic.map { GenericType(name: $0.name, typeParameters: $0.typeParameters) }
        generic?.name = aliased.name
        let dictionary = typeName.dictionary.map { DictionaryType(name: $0.name, valueTypeName: $0.valueTypeName, valueType: $0.valueType, keyTypeName: $0.keyTypeName, keyType: $0.keyType) }
        dictionary?.name = aliased.name
        let array = typeName.array.map { ArrayType(name: $0.name, elementTypeName: $0.elementTypeName, elementType: $0.elementType) }
        array?.name = aliased.name

        return TypeName(name: aliased.name,
                        isOptional: typeName.isOptional,
                        isImplicitlyUnwrappedOptional: typeName.isImplicitlyUnwrappedOptional,
                        tuple: aliased.typealias?.typeName.tuple ?? typeName.tuple, // TODO: verify
                        array: aliased.typealias?.typeName.array ?? array,
                        dictionary: aliased.typealias?.typeName.dictionary ?? dictionary,
                        closure: aliased.typealias?.typeName.closure ?? typeName.closure,
                        generic: aliased.typealias?.typeName.generic ?? generic
        )
    }

}
