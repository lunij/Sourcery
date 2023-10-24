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
        name = elements.asSource
        self.elements = elements
    }

    // sourcery:inline:TupleType.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
        guard let elements: [TupleElement] = aDecoder.decode(forKey: "elements") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["elements"])); fatalError() }; self.elements = elements
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(elements, forKey: "elements")
    }
    // sourcery:end
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

    // sourcery:inline:TupleElement.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decode(forKey: "name")
        guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
        type = aDecoder.decode(forKey: "type")
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(typeName, forKey: "typeName")
        aCoder.encode(type, forKey: "type")
    }
    // sourcery:end
}

public extension [TupleElement] {
    var asSource: String {
        "(\(map(\.asSource).joined(separator: ", ")))"
    }

    var asTypeName: String {
        "(\(map(\.typeName.asSource).joined(separator: ", ")))"
    }
}
