import Foundation

// sourcery: skipDescription
/// Descibes Swift actor
public final class Actor: Type {
    /// Returns "actor"
    public override var kind: String { return "actor" }

    /// Whether type is final
    public var isFinal: Bool {
        return modifiers.contains { $0.name == "final" }
    }

    public override init(name: String = "",
                         parent: Type? = nil,
                         accessLevel: AccessLevel = .internal,
                         isExtension: Bool = false,
                         variables: [Variable] = [],
                         methods: [Function] = [],
                         subscripts: [Subscript] = [],
                         inheritedTypes: [String] = [],
                         containedTypes: [Type] = [],
                         typealiases: [Typealias] = [],
                         attributes: AttributeList = [:],
                         modifiers: [Modifier] = [],
                         annotations: [String: AnnotationValue] = [:],
                         documentation: [String] = [],
                         isGeneric: Bool = false) {
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
            isGeneric: isGeneric
        )
    }

    public override func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Actor else {
            results.append("Incorrect type <expected: Actor, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: super.diffAgainst(castObject))
        return results
    }

    public override var description: String {
        var string = super.description
        string += ", "
        string += "kind = \(String(describing: kind)), "
        string += "isFinal = \(String(describing: isFinal))"
        return string
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
    }
}
