import Foundation

// sourcery: skipDescription
/// Describes Swift struct
@objcMembers public final class Struct: Type {

    /// Returns "struct"
    public override var kind: String { return "struct" }

    /// :nodoc:
    public override init(name: String = "",
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
}
