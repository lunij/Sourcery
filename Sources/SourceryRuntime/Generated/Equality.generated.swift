// Generated using Sourcery

// swiftlint:disable vertical_whitespace

public extension Actor {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Actor else { return false }
        return super.isEqual(rhs)
    }
}

public extension ArrayType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ArrayType else { return false }
        if name != rhs.name { return false }
        if elementTypeName != rhs.elementTypeName { return false }
        return true
    }
}

public extension AssociatedType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? AssociatedType else { return false }
        if name != rhs.name { return false }
        if typeName != rhs.typeName { return false }
        return true
    }
}

public extension AssociatedValue {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? AssociatedValue else { return false }
        if localName != rhs.localName { return false }
        if externalName != rhs.externalName { return false }
        if typeName != rhs.typeName { return false }
        if defaultValue != rhs.defaultValue { return false }
        if annotations != rhs.annotations { return false }
        return true
    }
}

public extension Attribute {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Attribute else { return false }
        if name != rhs.name { return false }
        if arguments != rhs.arguments { return false }
        if _description != rhs._description { return false }
        return true
    }
}

public extension BytesRange {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? BytesRange else { return false }
        if offset != rhs.offset { return false }
        if length != rhs.length { return false }
        return true
    }
}

public extension Class {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Class else { return false }
        return super.isEqual(rhs)
    }
}

public extension ClosureParameter {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ClosureParameter else { return false }
        if argumentLabel != rhs.argumentLabel { return false }
        if name != rhs.name { return false }
        if typeName != rhs.typeName { return false }
        if self.inout != rhs.inout { return false }
        if defaultValue != rhs.defaultValue { return false }
        if annotations != rhs.annotations { return false }
        return true
    }
}

public extension ClosureType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ClosureType else { return false }
        if name != rhs.name { return false }
        if parameters != rhs.parameters { return false }
        if returnTypeName != rhs.returnTypeName { return false }
        if isAsync != rhs.isAsync { return false }
        if asyncKeyword != rhs.asyncKeyword { return false }
        if self.throws != rhs.throws { return false }
        if throwsOrRethrowsKeyword != rhs.throwsOrRethrowsKeyword { return false }
        return true
    }
}

public extension DictionaryType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? DictionaryType else { return false }
        if name != rhs.name { return false }
        if valueTypeName != rhs.valueTypeName { return false }
        if keyTypeName != rhs.keyTypeName { return false }
        return true
    }
}

public extension DiffableResult {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? DiffableResult else { return false }
        if identifier != rhs.identifier { return false }
        return true
    }
}

public extension Enum {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Enum else { return false }
        if cases != rhs.cases { return false }
        if rawTypeName != rhs.rawTypeName { return false }
        return super.isEqual(rhs)
    }
}

public extension EnumCase {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? EnumCase else { return false }
        if name != rhs.name { return false }
        if rawValue != rhs.rawValue { return false }
        if associatedValues != rhs.associatedValues { return false }
        if annotations != rhs.annotations { return false }
        if documentation != rhs.documentation { return false }
        if indirect != rhs.indirect { return false }
        return true
    }
}

public extension FileParserResult {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? FileParserResult else { return false }
        if path != rhs.path { return false }
        if module != rhs.module { return false }
        if types != rhs.types { return false }
        if functions != rhs.functions { return false }
        if typealiases != rhs.typealiases { return false }
        if inlineRanges != rhs.inlineRanges { return false }
        if inlineIndentations != rhs.inlineIndentations { return false }
        if modifiedDate != rhs.modifiedDate { return false }
        return true
    }
}

public extension GenericRequirement {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? GenericRequirement else { return false }
        if leftType != rhs.leftType { return false }
        if rightType != rhs.rightType { return false }
        if relationship != rhs.relationship { return false }
        if relationshipSyntax != rhs.relationshipSyntax { return false }
        return true
    }
}

public extension GenericType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? GenericType else { return false }
        if name != rhs.name { return false }
        if typeParameters != rhs.typeParameters { return false }
        return true
    }
}

public extension GenericTypeParameter {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? GenericTypeParameter else { return false }
        if typeName != rhs.typeName { return false }
        return true
    }
}

public extension Import {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Import else { return false }
        if kind != rhs.kind { return false }
        if path != rhs.path { return false }
        return true
    }
}

public extension Method {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Method else { return false }
        if name != rhs.name { return false }
        if selectorName != rhs.selectorName { return false }
        if parameters != rhs.parameters { return false }
        if returnTypeName != rhs.returnTypeName { return false }
        if isAsync != rhs.isAsync { return false }
        if self.throws != rhs.throws { return false }
        if self.rethrows != rhs.rethrows { return false }
        if accessLevel != rhs.accessLevel { return false }
        if isStatic != rhs.isStatic { return false }
        if isClass != rhs.isClass { return false }
        if isFailableInitializer != rhs.isFailableInitializer { return false }
        if annotations != rhs.annotations { return false }
        if documentation != rhs.documentation { return false }
        if definedInTypeName != rhs.definedInTypeName { return false }
        if attributes != rhs.attributes { return false }
        if modifiers != rhs.modifiers { return false }
        return true
    }
}

public extension MethodParameter {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? MethodParameter else { return false }
        if argumentLabel != rhs.argumentLabel { return false }
        if name != rhs.name { return false }
        if typeName != rhs.typeName { return false }
        if self.inout != rhs.inout { return false }
        if isVariadic != rhs.isVariadic { return false }
        if defaultValue != rhs.defaultValue { return false }
        if annotations != rhs.annotations { return false }
        return true
    }
}

public extension Modifier {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Modifier else { return false }
        if name != rhs.name { return false }
        if detail != rhs.detail { return false }
        return true
    }
}

public extension Protocol {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Protocol else { return false }
        if associatedTypes != rhs.associatedTypes { return false }
        if genericRequirements != rhs.genericRequirements { return false }
        return super.isEqual(rhs)
    }
}

public extension ProtocolComposition {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ProtocolComposition else { return false }
        if composedTypeNames != rhs.composedTypeNames { return false }
        return super.isEqual(rhs)
    }
}

public extension Struct {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Struct else { return false }
        return super.isEqual(rhs)
    }
}

public extension Subscript {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Subscript else { return false }
        if parameters != rhs.parameters { return false }
        if returnTypeName != rhs.returnTypeName { return false }
        if readAccess != rhs.readAccess { return false }
        if writeAccess != rhs.writeAccess { return false }
        if annotations != rhs.annotations { return false }
        if documentation != rhs.documentation { return false }
        if definedInTypeName != rhs.definedInTypeName { return false }
        if attributes != rhs.attributes { return false }
        if modifiers != rhs.modifiers { return false }
        return true
    }
}

public extension TemplateContext {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TemplateContext else { return false }
        if parserResult != rhs.parserResult { return false }
        if functions != rhs.functions { return false }
        if types != rhs.types { return false }
        if argument != rhs.argument { return false }
        return true
    }
}

public extension TupleElement {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TupleElement else { return false }
        if name != rhs.name { return false }
        if typeName != rhs.typeName { return false }
        return true
    }
}

public extension TupleType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TupleType else { return false }
        if name != rhs.name { return false }
        if elements != rhs.elements { return false }
        return true
    }
}

public extension Type {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Type else { return false }
        if module != rhs.module { return false }
        if imports != rhs.imports { return false }
        if typealiases != rhs.typealiases { return false }
        if isExtension != rhs.isExtension { return false }
        if accessLevel != rhs.accessLevel { return false }
        if isUnknownExtension != rhs.isUnknownExtension { return false }
        if isGeneric != rhs.isGeneric { return false }
        if localName != rhs.localName { return false }
        if rawVariables != rhs.rawVariables { return false }
        if rawMethods != rhs.rawMethods { return false }
        if rawSubscripts != rhs.rawSubscripts { return false }
        if annotations != rhs.annotations { return false }
        if documentation != rhs.documentation { return false }
        if inheritedTypes != rhs.inheritedTypes { return false }
        if inherits != rhs.inherits { return false }
        if containedTypes != rhs.containedTypes { return false }
        if parentName != rhs.parentName { return false }
        if attributes != rhs.attributes { return false }
        if modifiers != rhs.modifiers { return false }
        if fileName != rhs.fileName { return false }
        if kind != rhs.kind { return false }
        return true
    }
}

public extension TypeName {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TypeName else { return false }
        if name != rhs.name { return false }
        if generic != rhs.generic { return false }
        if isProtocolComposition != rhs.isProtocolComposition { return false }
        if attributes != rhs.attributes { return false }
        if modifiers != rhs.modifiers { return false }
        if tuple != rhs.tuple { return false }
        if array != rhs.array { return false }
        if dictionary != rhs.dictionary { return false }
        if closure != rhs.closure { return false }
        return true
    }
}

public extension Typealias {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Typealias else { return false }
        if aliasName != rhs.aliasName { return false }
        if typeName != rhs.typeName { return false }
        if module != rhs.module { return false }
        if accessLevel != rhs.accessLevel { return false }
        if parentName != rhs.parentName { return false }
        return true
    }
}

public extension Types {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Types else { return false }
        if types != rhs.types { return false }
        if typealiases != rhs.typealiases { return false }
        return true
    }
}

public extension Variable {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Variable else { return false }
        if name != rhs.name { return false }
        if typeName != rhs.typeName { return false }
        if isComputed != rhs.isComputed { return false }
        if isAsync != rhs.isAsync { return false }
        if self.throws != rhs.throws { return false }
        if isStatic != rhs.isStatic { return false }
        if readAccess != rhs.readAccess { return false }
        if writeAccess != rhs.writeAccess { return false }
        if defaultValue != rhs.defaultValue { return false }
        if annotations != rhs.annotations { return false }
        if documentation != rhs.documentation { return false }
        if attributes != rhs.attributes { return false }
        if modifiers != rhs.modifiers { return false }
        if definedInTypeName != rhs.definedInTypeName { return false }
        return true
    }
}

// MARK: - Actor AutoHashable

public extension Actor {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - ArrayType AutoHashable

public extension ArrayType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(elementTypeName)
        return hasher.finalize()
    }
}

// MARK: - AssociatedType AutoHashable

public extension AssociatedType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(typeName)
        return hasher.finalize()
    }
}

// MARK: - AssociatedValue AutoHashable

public extension AssociatedValue {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(localName)
        hasher.combine(externalName)
        hasher.combine(typeName)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
        return hasher.finalize()
    }
}

// MARK: - Attribute AutoHashable

public extension Attribute {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(arguments)
        hasher.combine(_description)
        return hasher.finalize()
    }
}

// MARK: - BytesRange AutoHashable

public extension BytesRange {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(offset)
        hasher.combine(length)
        return hasher.finalize()
    }
}

// MARK: - Class AutoHashable

public extension Class {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - ClosureParameter AutoHashable

public extension ClosureParameter {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(argumentLabel)
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(self.inout)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
        return hasher.finalize()
    }
}

// MARK: - ClosureType AutoHashable

public extension ClosureType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(parameters)
        hasher.combine(returnTypeName)
        hasher.combine(isAsync)
        hasher.combine(asyncKeyword)
        hasher.combine(self.throws)
        hasher.combine(throwsOrRethrowsKeyword)
        return hasher.finalize()
    }
}

// MARK: - DictionaryType AutoHashable

public extension DictionaryType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(valueTypeName)
        hasher.combine(keyTypeName)
        return hasher.finalize()
    }
}

// MARK: - DiffableResult AutoHashable

public extension DiffableResult {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        return hasher.finalize()
    }
}

// MARK: - Enum AutoHashable

public extension Enum {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(cases)
        hasher.combine(rawTypeName)
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - EnumCase AutoHashable

public extension EnumCase {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(rawValue)
        hasher.combine(associatedValues)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(indirect)
        return hasher.finalize()
    }
}

// MARK: - FileParserResult AutoHashable

public extension FileParserResult {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(path)
        hasher.combine(module)
        hasher.combine(types)
        hasher.combine(functions)
        hasher.combine(typealiases)
        hasher.combine(inlineRanges)
        hasher.combine(inlineIndentations)
        hasher.combine(modifiedDate)
        return hasher.finalize()
    }
}

// MARK: - GenericRequirement AutoHashable

public extension GenericRequirement {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(leftType)
        hasher.combine(rightType)
        hasher.combine(relationship)
        hasher.combine(relationshipSyntax)
        return hasher.finalize()
    }
}

// MARK: - GenericType AutoHashable

public extension GenericType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(typeParameters)
        return hasher.finalize()
    }
}

// MARK: - GenericTypeParameter AutoHashable

public extension GenericTypeParameter {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(typeName)
        return hasher.finalize()
    }
}

// MARK: - Import AutoHashable

public extension Import {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(kind)
        hasher.combine(path)
        return hasher.finalize()
    }
}

// MARK: - Method AutoHashable

public extension Method {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(selectorName)
        hasher.combine(parameters)
        hasher.combine(returnTypeName)
        hasher.combine(isAsync)
        hasher.combine(self.throws)
        hasher.combine(self.rethrows)
        hasher.combine(accessLevel)
        hasher.combine(isStatic)
        hasher.combine(isClass)
        hasher.combine(isFailableInitializer)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(definedInTypeName)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        return hasher.finalize()
    }
}

// MARK: - MethodParameter AutoHashable

public extension MethodParameter {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(argumentLabel)
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(self.inout)
        hasher.combine(isVariadic)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
        return hasher.finalize()
    }
}

// MARK: - Modifier AutoHashable

public extension Modifier {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(detail)
        return hasher.finalize()
    }
}

// MARK: - Protocol AutoHashable

public extension Protocol {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(associatedTypes)
        hasher.combine(genericRequirements)
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - ProtocolComposition AutoHashable

public extension ProtocolComposition {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(composedTypeNames)
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - Struct AutoHashable

public extension Struct {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        return hasher.finalize()
    }
}

// MARK: - Subscript AutoHashable

public extension Subscript {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(parameters)
        hasher.combine(returnTypeName)
        hasher.combine(readAccess)
        hasher.combine(writeAccess)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(definedInTypeName)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        return hasher.finalize()
    }
}

// MARK: - TemplateContext AutoHashable

public extension TemplateContext {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(parserResult)
        hasher.combine(functions)
        hasher.combine(types)
        hasher.combine(argument)
        return hasher.finalize()
    }
}

// MARK: - TupleElement AutoHashable

public extension TupleElement {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(typeName)
        return hasher.finalize()
    }
}

// MARK: - TupleType AutoHashable

public extension TupleType {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(elements)
        return hasher.finalize()
    }
}

// MARK: - Type AutoHashable

public extension Type {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(module)
        hasher.combine(imports)
        hasher.combine(typealiases)
        hasher.combine(isExtension)
        hasher.combine(accessLevel)
        hasher.combine(isUnknownExtension)
        hasher.combine(isGeneric)
        hasher.combine(localName)
        hasher.combine(rawVariables)
        hasher.combine(rawMethods)
        hasher.combine(rawSubscripts)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(inheritedTypes)
        hasher.combine(inherits)
        hasher.combine(containedTypes)
        hasher.combine(parentName)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        hasher.combine(fileName)
        hasher.combine(kind)
        return hasher.finalize()
    }
}

// MARK: - TypeName AutoHashable

public extension TypeName {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(generic)
        hasher.combine(isProtocolComposition)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        hasher.combine(tuple)
        hasher.combine(array)
        hasher.combine(dictionary)
        hasher.combine(closure)
        return hasher.finalize()
    }
}

// MARK: - Typealias AutoHashable

public extension Typealias {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(aliasName)
        hasher.combine(typeName)
        hasher.combine(module)
        hasher.combine(accessLevel)
        hasher.combine(parentName)
        return hasher.finalize()
    }
}

// MARK: - Types AutoHashable

public extension Types {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(types)
        hasher.combine(typealiases)
        return hasher.finalize()
    }
}

// MARK: - Variable AutoHashable

public extension Variable {
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(isComputed)
        hasher.combine(isAsync)
        hasher.combine(self.throws)
        hasher.combine(isStatic)
        hasher.combine(readAccess)
        hasher.combine(writeAccess)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        hasher.combine(definedInTypeName)
        return hasher.finalize()
    }
}
