// Generated using Sourcery

// swiftlint:disable vertical_whitespace

public extension Actor {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind)), "
        string += "isFinal = \(String(describing: isFinal))"
        return string
    }
}

public extension ArrayType {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "elementTypeName = \(String(describing: elementTypeName)), "
        string += "asGeneric = \(String(describing: asGeneric)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension AssociatedType {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName))"
        return string
    }
}

public extension AssociatedValue {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "localName = \(String(describing: localName)), "
        string += "externalName = \(String(describing: externalName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations))"
        return string
    }
}

public extension BytesRange {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "offset = \(String(describing: offset)), "
        string += "length = \(String(describing: length))"
        return string
    }
}

public extension Class {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind)), "
        string += "isFinal = \(String(describing: isFinal))"
        return string
    }
}

public extension ClosureParameter {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "argumentLabel = \(String(describing: argumentLabel)), "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "`inout` = \(String(describing: self.inout)), "
        string += "typeAttributes = \(String(describing: typeAttributes)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension ClosureType {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "parameters = \(String(describing: parameters)), "
        string += "returnTypeName = \(String(describing: returnTypeName)), "
        string += "actualReturnTypeName = \(String(describing: actualReturnTypeName)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "asyncKeyword = \(String(describing: asyncKeyword)), "
        string += "`throws` = \(String(describing: self.throws)), "
        string += "throwsOrRethrowsKeyword = \(String(describing: throwsOrRethrowsKeyword)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension DictionaryType {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "valueTypeName = \(String(describing: valueTypeName)), "
        string += "keyTypeName = \(String(describing: keyTypeName)), "
        string += "asGeneric = \(String(describing: asGeneric)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension Enum {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "cases = \(String(describing: cases)), "
        string += "rawTypeName = \(String(describing: rawTypeName)), "
        string += "hasAssociatedValues = \(String(describing: hasAssociatedValues))"
        return string
    }
}

public extension EnumCase {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "rawValue = \(String(describing: rawValue)), "
        string += "associatedValues = \(String(describing: associatedValues)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "indirect = \(String(describing: indirect)), "
        string += "hasAssociatedValue = \(String(describing: hasAssociatedValue))"
        return string
    }
}

public extension FileParserResult {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "path = \(String(describing: path)), "
        string += "module = \(String(describing: module)), "
        string += "types = \(String(describing: types)), "
        string += "functions = \(String(describing: functions)), "
        string += "typealiases = \(String(describing: typealiases)), "
        string += "inlineRanges = \(String(describing: inlineRanges)), "
        string += "inlineIndentations = \(String(describing: inlineIndentations)), "
        string += "modifiedDate = \(String(describing: modifiedDate)), "
        string += "isEmpty = \(String(describing: isEmpty))"
        return string
    }
}

public extension GenericRequirement {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "leftType = \(String(describing: leftType)), "
        string += "rightType = \(String(describing: rightType)), "
        string += "relationship = \(String(describing: relationship)), "
        string += "relationshipSyntax = \(String(describing: relationshipSyntax))"
        return string
    }
}

public extension GenericTypeParameter {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "typeName = \(String(describing: typeName))"
        return string
    }
}

public extension Method {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "selectorName = \(String(describing: selectorName)), "
        string += "parameters = \(String(describing: parameters)), "
        string += "returnTypeName = \(String(describing: returnTypeName)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "`throws` = \(String(describing: self.throws)), "
        string += "`rethrows` = \(String(describing: self.rethrows)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "isStatic = \(String(describing: isStatic)), "
        string += "isClass = \(String(describing: isClass)), "
        string += "isFailableInitializer = \(String(describing: isFailableInitializer)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "definedInTypeName = \(String(describing: definedInTypeName)), "
        string += "attributes = \(String(describing: attributes)), "
        string += "modifiers = \(String(describing: modifiers))"
        return string
    }
}

public extension MethodParameter {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "argumentLabel = \(String(describing: argumentLabel)), "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "`inout` = \(String(describing: self.inout)), "
        string += "isVariadic = \(String(describing: isVariadic)), "
        string += "typeAttributes = \(String(describing: typeAttributes)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension Protocol {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind)), "
        string += "associatedTypes = \(String(describing: associatedTypes)), "
        string += "genericRequirements = \(String(describing: genericRequirements))"
        return string
    }
}

public extension ProtocolComposition {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind)), "
        string += "composedTypeNames = \(String(describing: composedTypeNames))"
        return string
    }
}

public extension Struct {
    /// :nodoc:
    override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind))"
        return string
    }
}

public extension Subscript {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "parameters = \(String(describing: parameters)), "
        string += "returnTypeName = \(String(describing: returnTypeName)), "
        string += "actualReturnTypeName = \(String(describing: actualReturnTypeName)), "
        string += "isFinal = \(String(describing: isFinal)), "
        string += "readAccess = \(String(describing: readAccess)), "
        string += "writeAccess = \(String(describing: writeAccess)), "
        string += "isMutable = \(String(describing: isMutable)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "definedInTypeName = \(String(describing: definedInTypeName)), "
        string += "actualDefinedInTypeName = \(String(describing: actualDefinedInTypeName)), "
        string += "attributes = \(String(describing: attributes)), "
        string += "modifiers = \(String(describing: modifiers))"
        return string
    }
}

public extension TemplateContext {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "parserResult = \(String(describing: parserResult)), "
        string += "functions = \(String(describing: functions)), "
        string += "types = \(String(describing: types)), "
        string += "argument = \(String(describing: argument)), "
        string += "stencilContext = \(String(describing: stencilContext))"
        return string
    }
}

public extension TupleElement {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

public extension TupleType {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "elements = \(String(describing: elements))"
        return string
    }
}

public extension Type {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "module = \(String(describing: module)), "
        string += "imports = \(String(describing: imports)), "
        string += "allImports = \(String(describing: allImports)), "
        string += "typealiases = \(String(describing: typealiases)), "
        string += "isExtension = \(String(describing: isExtension)), "
        string += "kind = \(String(describing: kind)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "name = \(String(describing: name)), "
        string += "isUnknownExtension = \(String(describing: isUnknownExtension)), "
        string += "isGeneric = \(String(describing: isGeneric)), "
        string += "localName = \(String(describing: localName)), "
        string += "rawVariables = \(String(describing: rawVariables)), "
        string += "rawMethods = \(String(describing: rawMethods)), "
        string += "rawSubscripts = \(String(describing: rawSubscripts)), "
        string += "initializers = \(String(describing: initializers)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "staticVariables = \(String(describing: staticVariables)), "
        string += "staticMethods = \(String(describing: staticMethods)), "
        string += "classMethods = \(String(describing: classMethods)), "
        string += "instanceVariables = \(String(describing: instanceVariables)), "
        string += "instanceMethods = \(String(describing: instanceMethods)), "
        string += "computedVariables = \(String(describing: computedVariables)), "
        string += "storedVariables = \(String(describing: storedVariables)), "
        string += "inheritedTypes = \(String(describing: inheritedTypes)), "
        string += "inherits = \(String(describing: inherits)), "
        string += "containedTypes = \(String(describing: containedTypes)), "
        string += "parentName = \(String(describing: parentName)), "
        string += "parentTypes = \(String(describing: parentTypes)), "
        string += "attributes = \(String(describing: attributes)), "
        string += "modifiers = \(String(describing: modifiers)), "
        string += "fileName = \(String(describing: fileName))"
        return string
    }
}

public extension Typealias {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "aliasName = \(String(describing: aliasName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "module = \(String(describing: module)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "parentName = \(String(describing: parentName)), "
        string += "name = \(String(describing: name))"
        return string
    }
}

public extension Types {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "types = \(String(describing: types)), "
        string += "typealiases = \(String(describing: typealiases))"
        return string
    }
}

public extension Variable {
    /// :nodoc:
    override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "isComputed = \(String(describing: isComputed)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "`throws` = \(String(describing: self.throws)), "
        string += "isStatic = \(String(describing: isStatic)), "
        string += "readAccess = \(String(describing: readAccess)), "
        string += "writeAccess = \(String(describing: writeAccess)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "isMutable = \(String(describing: isMutable)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "attributes = \(String(describing: attributes)), "
        string += "modifiers = \(String(describing: modifiers)), "
        string += "isFinal = \(String(describing: isFinal)), "
        string += "isLazy = \(String(describing: isLazy)), "
        string += "definedInTypeName = \(String(describing: definedInTypeName)), "
        string += "actualDefinedInTypeName = \(String(describing: actualDefinedInTypeName))"
        return string
    }
}
