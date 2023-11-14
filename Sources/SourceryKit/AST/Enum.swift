import Foundation
import Stencil

/// Defines enum case associated value
public final class AssociatedValue: Diffable, Typed, Annotated, Equatable, Hashable, CustomStringConvertible, DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "actualTypeName": typeName.actualTypeName
        case "annotations": annotations
        case "defaultValue": defaultValue
        case "description": description
        case "externalName": externalName
        case "isArray": typeName.isArray
        case "isClosure": typeName.isClosure
        case "isDictionary": typeName.isDictionary
        case "isImplicitlyUnwrappedOptional": typeName.isImplicitlyUnwrappedOptional
        case "isOptional": typeName.isOptional
        case "isTuple": typeName.isTuple
        case "localName": localName
        case "type": type
        case "typeName": typeName
        case "unwrappedTypeName": typeName.unwrappedTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }

    /// Associated value local name.
    /// This is a name to be used to construct enum case value
    public let localName: String?

    /// Associated value external name.
    /// This is a name to be used to access value in value-bindig
    public let externalName: String?

    /// Associated value type name
    public let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Associated value type, if known
    public var type: Type?

    /// Associated value default value
    public let defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public init(localName: String?, externalName: String?, typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:]) {
        self.localName = localName
        self.externalName = externalName
        self.typeName = typeName
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
    }

    convenience init(name: String? = nil, typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:]) {
        self.init(localName: name, externalName: name, typeName: typeName, type: type, defaultValue: defaultValue, annotations: annotations)
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? AssociatedValue else {
            results.append("Incorrect type <expected: AssociatedValue, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "localName").trackDifference(actual: self.localName, expected: castObject.localName))
        results.append(contentsOf: DiffableResult(identifier: "externalName").trackDifference(actual: self.externalName, expected: castObject.externalName))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: self.defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: self.annotations, expected: castObject.annotations))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "localName = \(String(describing: localName)), "
        string += "externalName = \(String(describing: externalName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(localName)
        hasher.combine(externalName)
        hasher.combine(typeName)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
    }

    public static func == (lhs: AssociatedValue, rhs: AssociatedValue) -> Bool {
        if lhs.localName != rhs.localName { return false }
        if lhs.externalName != rhs.externalName { return false }
        if lhs.typeName != rhs.typeName { return false }
        if lhs.defaultValue != rhs.defaultValue { return false }
        if lhs.annotations != rhs.annotations { return false }
        return true
    }
}

/// Defines enum case
public final class EnumCase: Diffable, Annotated, Documented, Equatable, Hashable, CustomStringConvertible, DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "name": name
        case "rawValue": rawValue
        case "associatedValues": associatedValues
        case "annotations": annotations
        case "documentation": documentation
        case "indirect": indirect
        case "hasAssociatedValue": hasAssociatedValue
        case "__parserData": __parserData
        case "description": description
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }

    /// Enum case name
    public let name: String

    /// Enum case raw value, if any
    public let rawValue: String?

    /// Enum case associated values
    public let associatedValues: [AssociatedValue]

    /// Enum case annotations
    public var annotations: Annotations = [:]

    public var documentation: Documentation = []

    /// Whether enum case is indirect
    public let indirect: Bool

    /// Whether enum case has associated value
    public var hasAssociatedValue: Bool {
        return !associatedValues.isEmpty
    }

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding
    public var __parserData: Any?

    public init(name: String, rawValue: String? = nil, associatedValues: [AssociatedValue] = [], annotations: [String: NSObject] = [:], documentation: [String] = [], indirect: Bool = false) {
        self.name = name
        self.rawValue = rawValue
        self.associatedValues = associatedValues
        self.annotations = annotations
        self.documentation = documentation
        self.indirect = indirect
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? EnumCase else {
            results.append("Incorrect type <expected: EnumCase, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "rawValue").trackDifference(actual: self.rawValue, expected: castObject.rawValue))
        results.append(contentsOf: DiffableResult(identifier: "associatedValues").trackDifference(actual: self.associatedValues, expected: castObject.associatedValues))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: self.annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: self.documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "indirect").trackDifference(actual: self.indirect, expected: castObject.indirect))
        return results
    }

    public var description: String {
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(rawValue)
        hasher.combine(associatedValues)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(indirect)
    }

    public static func == (lhs: EnumCase, rhs: EnumCase) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.rawValue != rhs.rawValue { return false }
        if lhs.associatedValues != rhs.associatedValues { return false }
        if lhs.annotations != rhs.annotations { return false }
        if lhs.documentation != rhs.documentation { return false }
        if lhs.indirect != rhs.indirect { return false }
        return true
    }
}

/// Defines Swift enum
public final class Enum: Type {
    public override subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "based": based
        case "cases": cases
        case "description": description
        case "hasAssociatedValues": hasAssociatedValues
        case "hasRawType": hasRawType
        case "kind": kind
        case "rawType": rawType
        case "rawTypeName": rawTypeName
        default: super[dynamicMember: member]
        }
    }

    // sourcery: skipDescription
    /// Returns "enum"
    public override var kind: String { return "enum" }

    /// Enum cases
    public var cases: [EnumCase]

    /**
     Enum raw value type name, if any. This type is removed from enum's `based` and `inherited` types collections.

        - important: Unless raw type is specified explicitly via type alias RawValue it will be set to the first type in the inheritance chain.
     So if your enum does not have raw value but implements protocols you'll have to specify conformance to these protocols via extension to get enum with nil raw value type and all based and inherited types.
     */
    public var rawTypeName: TypeName? {
        didSet {
            if let rawTypeName = rawTypeName {
                hasRawType = true
                if let index = inheritedTypes.firstIndex(of: rawTypeName.name) {
                    inheritedTypes.remove(at: index)
                }
                if based[rawTypeName.name] != nil {
                    based[rawTypeName.name] = nil
                }
            } else {
                hasRawType = false
            }
        }
    }

    // sourcery: skipDescription, skipEquality
    public private(set) var hasRawType: Bool

    // sourcery: skipDescription, skipEquality
    /// Enum raw value type, if known
    public var rawType: Type?

    // sourcery: skipEquality, skipDescription, skipCoding
    /// Names of types or protocols this type inherits from, including unknown (not scanned) types
    public override var based: [String: String] {
        didSet {
            if let rawTypeName = rawTypeName, based[rawTypeName.name] != nil {
                based[rawTypeName.name] = nil
            }
        }
    }

    /// Whether enum contains any associated values
    public var hasAssociatedValues: Bool {
        return cases.contains(where: { $0.hasAssociatedValue })
    }

    public init(name: String = "",
                parent: Type? = nil,
                accessLevel: AccessLevel = .internal,
                isExtension: Bool = false,
                inheritedTypes: [String] = [],
                rawTypeName: TypeName? = nil,
                cases: [EnumCase] = [],
                variables: [Variable] = [],
                methods: [Function] = [],
                containedTypes: [Type] = [],
                typealiases: [Typealias] = [],
                attributes: AttributeList = [:],
                modifiers: [Modifier] = [],
                annotations: [String: NSObject] = [:],
                documentation: [String] = [],
                isGeneric: Bool = false) {

        self.cases = cases
        self.rawTypeName = rawTypeName
        self.hasRawType = rawTypeName != nil || !inheritedTypes.isEmpty

        super.init(name: name, parent: parent, accessLevel: accessLevel, isExtension: isExtension, variables: variables, methods: methods, inheritedTypes: inheritedTypes, containedTypes: containedTypes, typealiases: typealiases, attributes: attributes, modifiers: modifiers, annotations: annotations, documentation: documentation, isGeneric: isGeneric)

        if let rawTypeName = rawTypeName?.name, let index = self.inheritedTypes.firstIndex(of: rawTypeName) {
            self.inheritedTypes.remove(at: index)
        }
    }

    public override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Enum else {
            results.append("Incorrect type <expected: Enum, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "cases").trackDifference(actual: self.cases, expected: castObject.cases))
        results.append(contentsOf: DiffableResult(identifier: "rawTypeName").trackDifference(actual: self.rawTypeName, expected: castObject.rawTypeName))
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }

    public override var description: String {
        var string = super.description
        string += ", "
        string += "cases = \(String(describing: cases)), "
        string += "rawTypeName = \(String(describing: rawTypeName)), "
        string += "hasAssociatedValues = \(String(describing: hasAssociatedValues))"
        return string
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(cases)
        hasher.combine(rawTypeName)
        super.hash(into: &hasher)
    }

    override func isEqual(to instance: Type) -> Bool {
        guard super.isEqual(to: instance), let instance = instance as? Enum else {
            return false
        }
        return cases == instance.cases
            && rawTypeName == instance.rawTypeName
    }
}
