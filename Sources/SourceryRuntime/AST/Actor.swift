import Foundation

// sourcery: skipDescription
/// Descibes Swift actor
@objc(SwiftActor) @objcMembers public final class Actor: Type {
    /// Returns "actor"
    override public var kind: String { "actor" }

    /// Whether type is final
    public var isFinal: Bool {
        modifiers.contains { $0.name == "final" }
    }

    /// :nodoc:
    override public init(
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

    // sourcery:inline:Actor.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// :nodoc:
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    // sourcery:end
}
