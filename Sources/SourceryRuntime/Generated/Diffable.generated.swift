// Generated using Sourcery

import Foundation

public extension Actor {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Actor else {
            results.append("Incorrect type <expected: Actor, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

extension ArrayType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? ArrayType else {
            results.append("Incorrect type <expected: ArrayType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "elementTypeName").trackDifference(actual: elementTypeName, expected: castObject.elementTypeName))
        return results
    }
}

extension AssociatedType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? AssociatedType else {
            results.append("Incorrect type <expected: AssociatedType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        return results
    }
}

extension AssociatedValue: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? AssociatedValue else {
            results.append("Incorrect type <expected: AssociatedValue, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "localName").trackDifference(actual: localName, expected: castObject.localName))
        results.append(contentsOf: DiffableResult(identifier: "externalName").trackDifference(actual: externalName, expected: castObject.externalName))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        return results
    }
}

extension Attribute: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Attribute else {
            results.append("Incorrect type <expected: Attribute, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "arguments").trackDifference(actual: arguments, expected: castObject.arguments))
        results.append(contentsOf: DiffableResult(identifier: "_description").trackDifference(actual: _description, expected: castObject._description))
        return results
    }
}

extension BytesRange: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? BytesRange else {
            results.append("Incorrect type <expected: BytesRange, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "offset").trackDifference(actual: offset, expected: castObject.offset))
        results.append(contentsOf: DiffableResult(identifier: "length").trackDifference(actual: length, expected: castObject.length))
        return results
    }
}

public extension Class {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Class else {
            results.append("Incorrect type <expected: Class, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

extension ClosureType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? ClosureType else {
            results.append("Incorrect type <expected: ClosureType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "asyncKeyword").trackDifference(actual: asyncKeyword, expected: castObject.asyncKeyword))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.throws, expected: castObject.throws))
        results.append(contentsOf: DiffableResult(identifier: "throwsOrRethrowsKeyword").trackDifference(actual: throwsOrRethrowsKeyword, expected: castObject.throwsOrRethrowsKeyword))
        return results
    }
}

extension DictionaryType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? DictionaryType else {
            results.append("Incorrect type <expected: DictionaryType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "valueTypeName").trackDifference(actual: valueTypeName, expected: castObject.valueTypeName))
        results.append(contentsOf: DiffableResult(identifier: "keyTypeName").trackDifference(actual: keyTypeName, expected: castObject.keyTypeName))
        return results
    }
}

public extension Enum {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Enum else {
            results.append("Incorrect type <expected: Enum, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "cases").trackDifference(actual: cases, expected: castObject.cases))
        results.append(contentsOf: DiffableResult(identifier: "rawTypeName").trackDifference(actual: rawTypeName, expected: castObject.rawTypeName))
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

extension EnumCase: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? EnumCase else {
            results.append("Incorrect type <expected: EnumCase, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "rawValue").trackDifference(actual: rawValue, expected: castObject.rawValue))
        results.append(contentsOf: DiffableResult(identifier: "associatedValues").trackDifference(actual: associatedValues, expected: castObject.associatedValues))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "indirect").trackDifference(actual: indirect, expected: castObject.indirect))
        return results
    }
}

extension FileParserResult: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? FileParserResult else {
            results.append("Incorrect type <expected: FileParserResult, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "path").trackDifference(actual: path, expected: castObject.path))
        results.append(contentsOf: DiffableResult(identifier: "module").trackDifference(actual: module, expected: castObject.module))
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "functions").trackDifference(actual: functions, expected: castObject.functions))
        results.append(contentsOf: DiffableResult(identifier: "typealiases").trackDifference(actual: typealiases, expected: castObject.typealiases))
        results.append(contentsOf: DiffableResult(identifier: "inlineRanges").trackDifference(actual: inlineRanges, expected: castObject.inlineRanges))
        results.append(contentsOf: DiffableResult(identifier: "inlineIndentations").trackDifference(actual: inlineIndentations, expected: castObject.inlineIndentations))
        results.append(contentsOf: DiffableResult(identifier: "modifiedDate").trackDifference(actual: modifiedDate, expected: castObject.modifiedDate))
        return results
    }
}

extension GenericRequirement: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericRequirement else {
            results.append("Incorrect type <expected: GenericRequirement, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "leftType").trackDifference(actual: leftType, expected: castObject.leftType))
        results.append(contentsOf: DiffableResult(identifier: "rightType").trackDifference(actual: rightType, expected: castObject.rightType))
        results.append(contentsOf: DiffableResult(identifier: "relationship").trackDifference(actual: relationship, expected: castObject.relationship))
        results.append(contentsOf: DiffableResult(identifier: "relationshipSyntax").trackDifference(actual: relationshipSyntax, expected: castObject.relationshipSyntax))
        return results
    }
}

extension GenericType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericType else {
            results.append("Incorrect type <expected: GenericType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeParameters").trackDifference(actual: typeParameters, expected: castObject.typeParameters))
        return results
    }
}

extension GenericTypeParameter: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericTypeParameter else {
            results.append("Incorrect type <expected: GenericTypeParameter, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        return results
    }
}

extension Import: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Import else {
            results.append("Incorrect type <expected: Import, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "kind").trackDifference(actual: kind, expected: castObject.kind))
        results.append(contentsOf: DiffableResult(identifier: "path").trackDifference(actual: path, expected: castObject.path))
        return results
    }
}

extension Method: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Method else {
            results.append("Incorrect type <expected: Method, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "selectorName").trackDifference(actual: selectorName, expected: castObject.selectorName))
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.throws, expected: castObject.throws))
        results.append(contentsOf: DiffableResult(identifier: "`rethrows`").trackDifference(actual: self.rethrows, expected: castObject.rethrows))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "isStatic").trackDifference(actual: isStatic, expected: castObject.isStatic))
        results.append(contentsOf: DiffableResult(identifier: "isClass").trackDifference(actual: isClass, expected: castObject.isClass))
        results.append(contentsOf: DiffableResult(identifier: "isFailableInitializer").trackDifference(actual: isFailableInitializer, expected: castObject.isFailableInitializer))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: definedInTypeName, expected: castObject.definedInTypeName))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        return results
    }
}

extension MethodParameter: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? MethodParameter else {
            results.append("Incorrect type <expected: MethodParameter, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "argumentLabel").trackDifference(actual: argumentLabel, expected: castObject.argumentLabel))
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "`inout`").trackDifference(actual: self.inout, expected: castObject.inout))
        results.append(contentsOf: DiffableResult(identifier: "isVariadic").trackDifference(actual: isVariadic, expected: castObject.isVariadic))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        return results
    }
}

extension Modifier: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Modifier else {
            results.append("Incorrect type <expected: Modifier, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "detail").trackDifference(actual: detail, expected: castObject.detail))
        return results
    }
}

public extension Protocol {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Protocol else {
            results.append("Incorrect type <expected: Protocol, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "associatedTypes").trackDifference(actual: associatedTypes, expected: castObject.associatedTypes))
        results.append(contentsOf: DiffableResult(identifier: "genericRequirements").trackDifference(actual: genericRequirements, expected: castObject.genericRequirements))
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

public extension ProtocolComposition {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? ProtocolComposition else {
            results.append("Incorrect type <expected: ProtocolComposition, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "composedTypeNames").trackDifference(actual: composedTypeNames, expected: castObject.composedTypeNames))
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

public extension Struct {
    override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Struct else {
            results.append("Incorrect type <expected: Struct, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }
}

extension Subscript: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Subscript else {
            results.append("Incorrect type <expected: Subscript, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "readAccess").trackDifference(actual: readAccess, expected: castObject.readAccess))
        results.append(contentsOf: DiffableResult(identifier: "writeAccess").trackDifference(actual: writeAccess, expected: castObject.writeAccess))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: definedInTypeName, expected: castObject.definedInTypeName))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        return results
    }
}

extension TemplateContext: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TemplateContext else {
            results.append("Incorrect type <expected: TemplateContext, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "parserResult").trackDifference(actual: parserResult, expected: castObject.parserResult))
        results.append(contentsOf: DiffableResult(identifier: "functions").trackDifference(actual: functions, expected: castObject.functions))
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "argument").trackDifference(actual: argument, expected: castObject.argument))
        return results
    }
}

extension TupleElement: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TupleElement else {
            results.append("Incorrect type <expected: TupleElement, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        return results
    }
}

extension TupleType: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TupleType else {
            results.append("Incorrect type <expected: TupleType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "elements").trackDifference(actual: elements, expected: castObject.elements))
        return results
    }
}

extension Type: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Type else {
            results.append("Incorrect type <expected: Type, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "module").trackDifference(actual: module, expected: castObject.module))
        results.append(contentsOf: DiffableResult(identifier: "imports").trackDifference(actual: imports, expected: castObject.imports))
        results.append(contentsOf: DiffableResult(identifier: "typealiases").trackDifference(actual: typealiases, expected: castObject.typealiases))
        results.append(contentsOf: DiffableResult(identifier: "isExtension").trackDifference(actual: isExtension, expected: castObject.isExtension))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "isUnknownExtension").trackDifference(actual: isUnknownExtension, expected: castObject.isUnknownExtension))
        results.append(contentsOf: DiffableResult(identifier: "isGeneric").trackDifference(actual: isGeneric, expected: castObject.isGeneric))
        results.append(contentsOf: DiffableResult(identifier: "localName").trackDifference(actual: localName, expected: castObject.localName))
        results.append(contentsOf: DiffableResult(identifier: "rawVariables").trackDifference(actual: rawVariables, expected: castObject.rawVariables))
        results.append(contentsOf: DiffableResult(identifier: "rawMethods").trackDifference(actual: rawMethods, expected: castObject.rawMethods))
        results.append(contentsOf: DiffableResult(identifier: "rawSubscripts").trackDifference(actual: rawSubscripts, expected: castObject.rawSubscripts))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "inheritedTypes").trackDifference(actual: inheritedTypes, expected: castObject.inheritedTypes))
        results.append(contentsOf: DiffableResult(identifier: "inherits").trackDifference(actual: inherits, expected: castObject.inherits))
        results.append(contentsOf: DiffableResult(identifier: "containedTypes").trackDifference(actual: containedTypes, expected: castObject.containedTypes))
        results.append(contentsOf: DiffableResult(identifier: "parentName").trackDifference(actual: parentName, expected: castObject.parentName))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        results.append(contentsOf: DiffableResult(identifier: "fileName").trackDifference(actual: fileName, expected: castObject.fileName))
        return results
    }
}

extension TypeName: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TypeName else {
            results.append("Incorrect type <expected: TypeName, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "generic").trackDifference(actual: generic, expected: castObject.generic))
        results.append(contentsOf: DiffableResult(identifier: "isProtocolComposition").trackDifference(actual: isProtocolComposition, expected: castObject.isProtocolComposition))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        results.append(contentsOf: DiffableResult(identifier: "tuple").trackDifference(actual: tuple, expected: castObject.tuple))
        results.append(contentsOf: DiffableResult(identifier: "array").trackDifference(actual: array, expected: castObject.array))
        results.append(contentsOf: DiffableResult(identifier: "dictionary").trackDifference(actual: dictionary, expected: castObject.dictionary))
        results.append(contentsOf: DiffableResult(identifier: "closure").trackDifference(actual: closure, expected: castObject.closure))
        return results
    }
}

extension Typealias: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Typealias else {
            results.append("Incorrect type <expected: Typealias, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "aliasName").trackDifference(actual: aliasName, expected: castObject.aliasName))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "module").trackDifference(actual: module, expected: castObject.module))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "parentName").trackDifference(actual: parentName, expected: castObject.parentName))
        return results
    }
}

extension Types: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Types else {
            results.append("Incorrect type <expected: Types, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "typealiases").trackDifference(actual: typealiases, expected: castObject.typealiases))
        return results
    }
}

extension Variable: Diffable {
    @objc public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Variable else {
            results.append("Incorrect type <expected: Variable, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "isComputed").trackDifference(actual: isComputed, expected: castObject.isComputed))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.throws, expected: castObject.throws))
        results.append(contentsOf: DiffableResult(identifier: "isStatic").trackDifference(actual: isStatic, expected: castObject.isStatic))
        results.append(contentsOf: DiffableResult(identifier: "readAccess").trackDifference(actual: readAccess, expected: castObject.readAccess))
        results.append(contentsOf: DiffableResult(identifier: "writeAccess").trackDifference(actual: writeAccess, expected: castObject.writeAccess))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: definedInTypeName, expected: castObject.definedInTypeName))
        return results
    }
}
