import Foundation
import Stencil

public typealias SourceryVariable = Variable

/// Defines variable
public final class Variable: Diffable, Typed, Annotated, Documented, Definition, Equatable, Hashable, CustomStringConvertible, DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "accessLevel": accessLevel
        case "actualDefinedInTypeName": actualDefinedInTypeName
        case "actualTypeName": typeName.actualTypeName
        case "annotations": annotations
        case "attributes": attributes
        case "defaultValue": defaultValue
        case "definedInType": definedInType
        case "definedInTypeName": definedInTypeName
        case "description": description
        case "documentation": documentation
        case "isArray": typeName.isArray
        case "isAsync": isAsync
        case "isClosure": typeName.isClosure
        case "isComputed": isComputed
        case "isDictionary": typeName.isDictionary
        case "isFinal": isFinal
        case "isImplicitlyUnwrappedOptional": typeName.isImplicitlyUnwrappedOptional
        case "isLazy": isLazy
        case "isMutable": isMutable
        case "isOptional": typeName.isOptional
        case "isStatic": isStatic
        case "isTuple": typeName.isTuple
        case "modifiers": modifiers
        case "name": name
        case "readAccess": readAccess
        case "throws": `throws`
        case "type": type
        case "typeName": typeName
        case "unwrappedTypeName": typeName.unwrappedTypeName
        case "writeAccess": writeAccess
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }

    /// Variable name
    public let name: String

    /// Variable type name
    public let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Variable type, if known, i.e. if the type is declared in the scanned sources.
    /// For explanation, see <https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/writing-templates.html#what-are-em-known-em-and-em-unknown-em-types>
    public var type: Type?

    /// Whether variable is computed and not stored
    public let isComputed: Bool
    
    /// Whether variable is async
    public let isAsync: Bool
    
    /// Whether variable throws
    public let `throws`: Bool

    /// Whether variable is static
    public let isStatic: Bool

    /// Variable read access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    public let readAccess: String

    /// Variable write access, i.e. `internal`, `private`, `fileprivate`, `public`, `open`.
    /// For immutable variables this value is empty string
    public let writeAccess: String

    /// composed access level
    public var accessLevel: (read: AccessLevel, write: AccessLevel) {
        (read: AccessLevel(rawValue: readAccess) ?? .none, AccessLevel(rawValue: writeAccess) ?? .none)
    }

    /// Whether variable is mutable or not
    public var isMutable: Bool {
        return writeAccess != AccessLevel.none.rawValue
    }

    /// Variable default value expression
    public var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public var documentation: Documentation = []

    /// Variable attributes, i.e. `@IBOutlet`, `@IBInspectable`
    public var attributes: AttributeList

    /// Modifiers, i.e. `private`
    public var modifiers: [Modifier]

    /// Whether variable is final or not
    public var isFinal: Bool {
        return modifiers.contains { $0.name == "final" }
    }

    /// Whether variable is lazy or not
    public var isLazy: Bool {
        return modifiers.contains { $0.name == "lazy" }
    }

    /// Reference to type name where the variable is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc
    public internal(set) var definedInTypeName: TypeName?

    /// Reference to actual type name where the method is defined if declaration uses typealias, otherwise just a `definedInTypeName`
    public var actualDefinedInTypeName: TypeName? {
        return definedInTypeName?.actualTypeName ?? definedInTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type where the object is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc or type is unknown
    public var definedInType: Type?

    public init(name: String = "",
                typeName: TypeName,
                type: Type? = nil,
                accessLevel: (read: AccessLevel, write: AccessLevel) = (.internal, .internal),
                isComputed: Bool = false,
                isAsync: Bool = false,
                `throws`: Bool = false,
                isStatic: Bool = false,
                defaultValue: String? = nil,
                attributes: AttributeList = [:],
                modifiers: [Modifier] = [],
                annotations: [String: AnnotationValue] = [:],
                documentation: [String] = [],
                definedInTypeName: TypeName? = nil) {

        self.name = name
        self.typeName = typeName
        self.type = type
        self.isComputed = isComputed
        self.isAsync = isAsync
        self.`throws` = `throws`
        self.isStatic = isStatic
        self.defaultValue = defaultValue
        self.readAccess = accessLevel.read.rawValue
        self.writeAccess = accessLevel.write.rawValue
        self.attributes = attributes
        self.modifiers = modifiers
        self.annotations = annotations
        self.documentation = documentation
        self.definedInTypeName = definedInTypeName
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Variable else {
            results.append("Incorrect type <expected: Variable, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "isComputed").trackDifference(actual: self.isComputed, expected: castObject.isComputed))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: self.isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.`throws`, expected: castObject.`throws`))
        results.append(contentsOf: DiffableResult(identifier: "isStatic").trackDifference(actual: self.isStatic, expected: castObject.isStatic))
        results.append(contentsOf: DiffableResult(identifier: "readAccess").trackDifference(actual: self.readAccess, expected: castObject.readAccess))
        results.append(contentsOf: DiffableResult(identifier: "writeAccess").trackDifference(actual: self.writeAccess, expected: castObject.writeAccess))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: self.defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: self.annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: self.documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: self.attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: self.modifiers, expected: castObject.modifiers))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: self.definedInTypeName, expected: castObject.definedInTypeName))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "isComputed = \(String(describing: isComputed)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "`throws` = \(String(describing: `throws`)), "
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(isComputed)
        hasher.combine(isAsync)
        hasher.combine(`throws`)
        hasher.combine(isStatic)
        hasher.combine(readAccess)
        hasher.combine(writeAccess)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        hasher.combine(definedInTypeName)
    }

    public static func == (lhs: Variable, rhs: Variable) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.typeName != rhs.typeName { return false }
        if lhs.isComputed != rhs.isComputed { return false }
        if lhs.isAsync != rhs.isAsync { return false }
        if lhs.`throws` != rhs.`throws` { return false }
        if lhs.isStatic != rhs.isStatic { return false }
        if lhs.readAccess != rhs.readAccess { return false }
        if lhs.writeAccess != rhs.writeAccess { return false }
        if lhs.defaultValue != rhs.defaultValue { return false }
        if lhs.annotations != rhs.annotations { return false }
        if lhs.documentation != rhs.documentation { return false }
        if lhs.attributes != rhs.attributes { return false }
        if lhs.modifiers != rhs.modifiers { return false }
        if lhs.definedInTypeName != rhs.definedInTypeName { return false }
        return true
    }
}
