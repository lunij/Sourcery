import Foundation

/// Describes Swift AssociatedType
@objcMembers public final class AssociatedType: NSObject, SourceryModel {
    /// Associated type name
    public let name: String

    /// Associated type type constraint name, if specified
    public let typeName: TypeName?

    // sourcery: skipEquality, skipDescription
    /// Associated type constrained type, if known, i.e. if the type is declared in the scanned sources.
    public var type: Type?

    /// :nodoc:
    public init(name: String, typeName: TypeName? = nil, type: Type? = nil) {
        self.name = name
        self.typeName = typeName
        self.type = type
    }

    // sourcery:inline:AssociatedType.AutoCoding
    public required init?(coder aDecoder: NSCoder) {
        guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
        typeName = aDecoder.decode(forKey: "typeName")
        type = aDecoder.decode(forKey: "type")
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(typeName, forKey: "typeName")
        aCoder.encode(type, forKey: "type")
    }
    // sourcery:end
}
