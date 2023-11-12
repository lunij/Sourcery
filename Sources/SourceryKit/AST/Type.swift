import DynamicMemberLookup
import Foundation
import OrderedCollections

public typealias AttributeList = [String: [Attribute]]

/// Defines Swift type
@DynamicMemberLookup
@objcMembers public class Type: NSObject, Annotated, Diffable, Documented {
    public var module: String?

    /// Imports that existed in the file that contained this type declaration
    public var imports: [Import] = []

    // sourcery: skipEquality
    /// Imports existed in all files containing this type and all its super classes/protocols
    public var allImports: [Import] {
        unique({ $0.gatherAllImports() }, filter: { $0 == $1 })
    }

    private func gatherAllImports() -> [Import] {
        var allImports: [Import] = Array(imports)

        basedTypes.values.forEach { basedType in
            allImports.append(contentsOf: basedType.imports)
        }
        return allImports
    }

    // All local typealiases
    public var typealiases: [String: Typealias] {
        didSet {
            typealiases.values.forEach { $0.parent = self }
        }
    }

    /// Whether declaration is an extension of some type
    public var isExtension: Bool

    // sourcery: forceEquality
    /// Kind of type declaration, i.e. `enum`, `struct`, `class`, `protocol` or `extension`
    public var kind: String { isExtension ? "extension" : "unknown" }

    /// Type access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    public let accessLevel: String

    /// Type name in global scope. For inner types includes the name of its containing type, i.e. `Type.Inner`
    public var name: String {
        guard let parentName = parent?.name else { return localName }
        return "\(parentName).\(localName)"
    }

    // sourcery: skipCoding
    /// Whether the type has been resolved as unknown extension
    public var isUnknownExtension: Bool = false

    // sourcery: skipDescription
    /// Global type name including module name, unless it's an extension of unknown type
    public var globalName: String {
        guard let module, !isUnknownExtension else { return name }
        return "\(module).\(name)"
    }

    /// Whether type is generic
    public var isGeneric: Bool

    /// Type name in its own scope.
    public var localName: String

    // sourcery: skipEquality, skipDescription
    /// Variables defined in this type only, inluding variables defined in its extensions,
    /// but not including variables inherited from superclasses (for classes only) and protocols
    public var variables: [Variable] {
        unique({ $0.rawVariables }, filter: Self.uniqueVariableFilter)
    }

    /// Unfiltered (can contain duplications from extensions) variables defined in this type only, inluding variables defined in its extensions,
    /// but not including variables inherited from superclasses (for classes only) and protocols
    public var rawVariables: [Variable]

    // sourcery: skipEquality, skipDescription
    /// All variables defined for this type, including variables defined in extensions,
    /// in superclasses (for classes only) and protocols
    public var allVariables: [Variable] {
        flattenAll(
            {
                $0.variables
            },
            isExtension: { $0.definedInType?.isExtension == true },
            filter: { all, extracted in
                !all.contains(where: { Self.uniqueVariableFilter($0, rhs: extracted) })
            }
        )
    }

    private static func uniqueVariableFilter(_ lhs: Variable, rhs: Variable) -> Bool {
        lhs.name == rhs.name && lhs.isStatic == rhs.isStatic && lhs.typeName == rhs.typeName
    }

    // sourcery: skipEquality, skipDescription
    /// Methods defined in this type only, inluding methods defined in its extensions,
    /// but not including methods inherited from superclasses (for classes only) and protocols
    public var methods: [Method] {
        unique({ $0.rawMethods }, filter: Self.uniqueMethodFilter)
    }

    /// Unfiltered (can contain duplications from extensions) methods defined in this type only, inluding methods defined in its extensions,
    /// but not including methods inherited from superclasses (for classes only) and protocols
    public var rawMethods: [Method]

    // sourcery: skipEquality, skipDescription
    /// All methods defined for this type, including methods defined in extensions,
    /// in superclasses (for classes only) and protocols
    public var allMethods: [Method] {
        flattenAll(
            {
                $0.methods
            },
            isExtension: { $0.definedInType?.isExtension == true },
            filter: { all, extracted in
                !all.contains(where: { Self.uniqueMethodFilter($0, rhs: extracted) })
            }
        )
    }

    private static func uniqueMethodFilter(_ lhs: Method, rhs: Method) -> Bool {
        lhs.name == rhs.name && lhs.isStatic == rhs.isStatic && lhs.isClass == rhs.isClass && lhs.actualReturnTypeName == rhs.actualReturnTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Subscripts defined in this type only, inluding subscripts defined in its extensions,
    /// but not including subscripts inherited from superclasses (for classes only) and protocols
    public var subscripts: [Subscript] {
        unique({ $0.rawSubscripts }, filter: Self.uniqueSubscriptFilter)
    }

    /// Unfiltered (can contain duplications from extensions) Subscripts defined in this type only, inluding subscripts defined in its extensions,
    /// but not including subscripts inherited from superclasses (for classes only) and protocols
    public var rawSubscripts: [Subscript]

    // sourcery: skipEquality, skipDescription
    /// All subscripts defined for this type, including subscripts defined in extensions,
    /// in superclasses (for classes only) and protocols
    public var allSubscripts: [Subscript] {
        flattenAll(
            { $0.subscripts },
            isExtension: { $0.definedInType?.isExtension == true },
            filter: { all, extracted in
                !all.contains(where: { Self.uniqueSubscriptFilter($0, rhs: extracted) })
            }
        )
    }

    private static func uniqueSubscriptFilter(_ lhs: Subscript, rhs: Subscript) -> Bool {
        lhs.parameters == rhs.parameters && lhs.returnTypeName == rhs.returnTypeName && lhs.readAccess == rhs.readAccess && lhs.writeAccess == rhs.writeAccess
    }

    // sourcery: skipEquality, skipDescription
    /// Bytes position of the body of this type in its declaration file if available.
    public var bodyBytesRange: BytesRange?

    // sourcery: skipEquality, skipDescription
    /// Bytes position of the whole declaration of this type in its declaration file if available.
    public var completeDeclarationRange: BytesRange?

    private func flattenAll<T: Hashable>(_ extraction: @escaping (Type) -> [T], isExtension: (T) -> Bool, filter: ([T], T) -> Bool) -> [T] {
        var all = OrderedSet<T>()
        let allObjects = extraction(self)

        /// The order of importance for properties is:
        /// Base class
        /// Inheritance
        /// Protocol conformance
        /// Extension

        var extensions = [T]()
        var baseObjects = [T]()

        allObjects.forEach {
            if isExtension($0) {
                extensions.append($0)
            } else {
                baseObjects.append($0)
            }
        }

        all.append(contentsOf: baseObjects)

        func filteredExtraction(_ target: Type) -> [T] {
            let extracted = extraction(target).filter { filter(all.elements, $0) }
            return extracted
        }

        inherits.values.sorted(by: { $0.name < $1.name }).forEach { all.append(contentsOf: filteredExtraction($0)) }
        implements.values.sorted(by: { $0.name < $1.name }).forEach { all.append(contentsOf: filteredExtraction($0)) }

        all.append(contentsOf: extensions.filter { filter(all.elements, $0) })

        return all.elements
    }

    private func unique<T: Hashable>(_ extraction: @escaping (Type) -> [T], filter: (T, T) -> Bool) -> [T] {
        var all = OrderedSet<T>()
        for nextItem in extraction(self) {
            if !all.contains(where: { filter($0, nextItem) }) {
                all.append(nextItem)
            }
        }
        return all.elements
    }

    /// All initializers defined in this type
    public var initializers: [Method] {
        methods.filter(\.isInitializer)
    }

    /// All annotations for this type
    public var annotations: Annotations = [:]

    public var documentation: Documentation = []

    /// Static variables defined in this type
    public var staticVariables: [Variable] {
        variables.filter(\.isStatic)
    }

    /// Static methods defined in this type
    public var staticMethods: [Method] {
        methods.filter(\.isStatic)
    }

    /// Class methods defined in this type
    public var classMethods: [Method] {
        methods.filter(\.isClass)
    }

    /// Instance variables defined in this type
    public var instanceVariables: [Variable] {
        variables.filter { !$0.isStatic }
    }

    /// Instance methods defined in this type
    public var instanceMethods: [Method] {
        methods.filter { !$0.isStatic && !$0.isClass }
    }

    /// Computed instance variables defined in this type
    public var computedVariables: [Variable] {
        variables.filter { $0.isComputed && !$0.isStatic }
    }

    /// Stored instance variables defined in this type
    public var storedVariables: [Variable] {
        variables.filter { !$0.isComputed && !$0.isStatic }
    }

    /// Names of types this type inherits from (for classes only) and protocols it implements, in order of definition
    public var inheritedTypes: [String] {
        didSet {
            based.removeAll()
            inheritedTypes.forEach { name in
                self.based[name] = name
            }
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Names of types or protocols this type inherits from, including unknown (not scanned) types
    public var based = [String: String]()

    // sourcery: skipEquality, skipDescription
    /// Types this type inherits from or implements, including unknown (not scanned) types with extensions defined
    public var basedTypes = [String: Type]()

    /// Types this type inherits from
    public var inherits = [String: Type]()

    // sourcery: skipEquality, skipDescription
    /// Protocols this type implements
    public var implements = [String: Type]()

    /// Contained types
    public var containedTypes: [Type] {
        didSet {
            containedTypes.forEach {
                containedType[$0.localName] = $0
                $0.parent = self
            }
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Contained types groupd by their names
    public private(set) var containedType: [String: Type] = [:]

    /// Name of parent type (for contained types only)
    public private(set) var parentName: String?

    // sourcery: skipEquality, skipDescription
    /// Parent type, if known (for contained types only)
    public var parent: Type? {
        didSet {
            parentName = parent?.name
        }
    }

    public var parentTypes: AnyIterator<Type> {
        var next: Type? = self
        return AnyIterator {
            next = next?.parent
            return next
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Superclass type, if known (only for classes)
    public var supertype: Type?

    /// Type attributes, i.e. `@objc`
    public var attributes: AttributeList

    /// Type modifiers, i.e. `private`, `final`
    public var modifiers: [SourceryModifier]

    /// Path to file where the type is defined
    // sourcery: skipDescription, skipEquality
    public var path: String? {
        didSet {
            if let path {
                fileName = (path as NSString).lastPathComponent
            }
        }
    }

    /// Directory to file where the type is defined
    // sourcery: skipDescription, skipEquality
    public var directory: String? {
        (path as? NSString)?.deletingLastPathComponent
    }

    /// File name where the type was defined
    public var fileName: String?

    public init(
        name: String = "",
        parent: Type? = nil,
        accessLevel: AccessLevel = .internal,
        isExtension: Bool = false,
        variables: [Variable] = [],
        methods: [Method] = [],
        subscripts: [Subscript] = [],
        inheritedTypes: [String] = [],
        containedTypes: [Type] = [],
        typealiases: [Typealias] = [],
        attributes: AttributeList = [:],
        modifiers: [SourceryModifier] = [],
        annotations: [String: NSObject] = [:],
        documentation: [String] = [],
        isGeneric: Bool = false
    ) {
        localName = name
        self.accessLevel = accessLevel.rawValue
        self.isExtension = isExtension
        rawVariables = variables
        rawMethods = methods
        rawSubscripts = subscripts
        self.inheritedTypes = inheritedTypes
        self.containedTypes = containedTypes
        self.typealiases = [:]
        self.parent = parent
        parentName = parent?.name
        self.attributes = attributes
        self.modifiers = modifiers
        self.annotations = annotations
        self.documentation = documentation
        self.isGeneric = isGeneric

        super.init()
        containedTypes.forEach {
            containedType[$0.localName] = $0
            $0.parent = self
        }
        inheritedTypes.forEach { name in
            self.based[name] = name
        }
        typealiases.forEach {
            $0.parent = self
            self.typealiases[$0.aliasName] = $0
        }
    }

    public func extend(_ type: Type) {
        type.annotations.forEach { self.annotations[$0.key] = $0.value }
        type.inherits.forEach { self.inherits[$0.key] = $0.value }
        type.implements.forEach { self.implements[$0.key] = $0.value }
        inheritedTypes += type.inheritedTypes
        containedTypes += type.containedTypes

        rawVariables += type.rawVariables
        rawMethods += type.rawMethods
        rawSubscripts += type.rawSubscripts
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
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

    override public var description: String {
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

extension Type {
    // sourcery: skipDescription
    var isClass: Bool {
        let isNotClass = self is Struct || self is Enum || self is Protocol
        return !isNotClass && !isExtension
    }
}
