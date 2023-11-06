import Foundation

/// Describes tuple type
@objcMembers public final class TupleType: NSObject, SourceryModel {

    /// Type name used in declaration
    public var name: String

    /// Tuple elements
    public var elements: [TupleElement]

    /// :nodoc:
    public init(name: String, elements: [TupleElement]) {
        self.name = name
        self.elements = elements
    }

    /// :nodoc:
    public init(elements: [TupleElement]) {
        self.name = elements.asSource
        self.elements = elements
    }
}

/// Describes tuple type element
@objcMembers public final class TupleElement: NSObject, SourceryModel, Typed {

    /// Tuple element name
    public let name: String?

    /// Tuple element type name
    public var typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Tuple element type, if known
    public var type: Type?

    /// :nodoc:
    public init(name: String? = nil, typeName: TypeName, type: Type? = nil) {
        self.name = name
        self.typeName = typeName
        self.type = type
    }

    public var asSource: String {
        // swiftlint:disable:next force_unwrapping
        "\(name != nil ? "\(name!): " : "")\(typeName.asSource)"
    }
}

extension Array where Element == TupleElement {
    public var asSource: String {
        "(\(map { $0.asSource }.joined(separator: ", ")))"
    }

    public var asTypeName: String {
        "(\(map { $0.typeName.asSource }.joined(separator: ", ")))"
    }
}
