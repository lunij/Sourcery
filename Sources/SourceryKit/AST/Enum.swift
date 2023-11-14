import Foundation
import Stencil

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

    /// Returns "enum"
    public override var kind: String { "enum" }

    /// Enum cases
    public var cases: [EnumCase]

    /// Enum raw value type name, if any. This type is removed from enum's `based` and `inherited` types collections.
    ///
    ///   - important: Unless raw type is specified explicitly via type alias RawValue it will be set to the first type in the inheritance chain.
    /// So if your enum does not have raw value but implements protocols you'll have to specify conformance to these protocols via extension to get enum with nil raw value type and all based and inherited types.
    public var rawTypeName: TypeName? {
        didSet {
            if let rawTypeName {
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

    public private(set) var hasRawType: Bool

    /// Enum raw value type, if known
    public var rawType: Type?

    /// Names of types or protocols this type inherits from, including unknown (not scanned) types
    public override var based: [String: String] {
        didSet {
            if let rawTypeName, based[rawTypeName.name] != nil {
                based[rawTypeName.name] = nil
            }
        }
    }

    /// Whether enum contains any associated values
    public var hasAssociatedValues: Bool {
        cases.contains(where: \.hasAssociatedValue)
    }

    public init(
        name: String = "",
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
        isGeneric: Bool = false
    ) {
        self.cases = cases
        self.rawTypeName = rawTypeName
        hasRawType = rawTypeName != nil || !inheritedTypes.isEmpty

        super.init(
            name: name,
            parent: parent,
            accessLevel: accessLevel,
            isExtension: isExtension,
            variables: variables,
            methods: methods,
            inheritedTypes: inheritedTypes,
            containedTypes: containedTypes,
            typealiases: typealiases,
            attributes: attributes,
            modifiers: modifiers,
            annotations: annotations,
            documentation: documentation,
            isGeneric: isGeneric
        )

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
        results.append(contentsOf: DiffableResult(identifier: "cases").trackDifference(actual: cases, expected: castObject.cases))
        results.append(contentsOf: DiffableResult(identifier: "rawTypeName").trackDifference(actual: rawTypeName, expected: castObject.rawTypeName))
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
