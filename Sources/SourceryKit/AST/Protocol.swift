import Foundation

public typealias SourceryProtocol = Protocol

/// Describes Swift protocol
public final class Protocol: Type {

    /// Returns "protocol"
    public override var kind: String { return "protocol" }

    /// list of all declared associated types with their names as keys
    public var associatedTypes: [String: AssociatedType] {
        didSet {
            isGeneric = !associatedTypes.isEmpty || !genericRequirements.isEmpty
        }
    }

    /// list of generic requirements
    public var genericRequirements: [GenericRequirement] {
        didSet {
            isGeneric = !associatedTypes.isEmpty || !genericRequirements.isEmpty
        }
    }

    public init(name: String = "",
                parent: Type? = nil,
                accessLevel: AccessLevel = .internal,
                isExtension: Bool = false,
                variables: [Variable] = [],
                methods: [Function] = [],
                subscripts: [Subscript] = [],
                inheritedTypes: [String] = [],
                containedTypes: [Type] = [],
                typealiases: [Typealias] = [],
                associatedTypes: [String: AssociatedType] = [:],
                genericRequirements: [GenericRequirement] = [],
                attributes: AttributeList = [:],
                modifiers: [Modifier] = [],
                annotations: [String: AnnotationValue] = [:],
                documentation: [String] = []) {
        self.genericRequirements = genericRequirements
        self.associatedTypes = associatedTypes
        super.init(
            name: name,
            parent: parent,
            accessLevel: accessLevel,
            isExtension: isExtension,
            variables: variables,
            methods: methods,
            subscripts: subscripts,
            inheritedTypes: inheritedTypes,
            containedTypes: containedTypes,
            typealiases: typealiases,
            attributes: attributes,
            modifiers: modifiers,
            annotations: annotations,
            documentation: documentation,
            isGeneric: !associatedTypes.isEmpty || !genericRequirements.isEmpty
        )
    }

    public override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Protocol else {
            results.append("Incorrect type <expected: Protocol, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "associatedTypes").trackDifference(actual: self.associatedTypes, expected: castObject.associatedTypes))
        results.append(contentsOf: DiffableResult(identifier: "genericRequirements").trackDifference(actual: self.genericRequirements, expected: castObject.genericRequirements))
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }

    public override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: self.kind)), "
        string += "associatedTypes = \(String(describing: self.associatedTypes)), "
        string += "genericRequirements = \(String(describing: self.genericRequirements))"
        return string
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(associatedTypes)
        hasher.combine(genericRequirements)
        super.hash(into: &hasher)
    }

    override func isEqual(to instance: Type) -> Bool {
        guard super.isEqual(to: instance), let instance = instance as? Protocol else {
            return false
        }
        return associatedTypes == instance.associatedTypes
            && genericRequirements == instance.genericRequirements
    }
}
