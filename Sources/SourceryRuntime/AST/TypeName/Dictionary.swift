import Foundation

/// Describes dictionary type
@objcMembers public final class DictionaryType: NSObject, SourceryModel {
    /// Type name used in declaration
    public var name: String

    /// Dictionary value type name
    public var valueTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Dictionary value type, if known
    public var valueType: Type?

    /// Dictionary key type name
    public var keyTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Dictionary key type, if known
    public var keyType: Type?

    /// :nodoc:
    public init(name: String, valueTypeName: TypeName, valueType: Type? = nil, keyTypeName: TypeName, keyType: Type? = nil) {
        self.name = name
        self.valueTypeName = valueTypeName
        self.valueType = valueType
        self.keyTypeName = keyTypeName
        self.keyType = keyType
    }

    /// Returns dictionary as generic type
    public var asGeneric: GenericType {
        GenericType(name: "Dictionary", typeParameters: [
            .init(typeName: keyTypeName),
            .init(typeName: valueTypeName)
        ])
    }

    public var asSource: String {
        "[\(keyTypeName.asSource): \(valueTypeName.asSource)]"
    }

    // sourcery:inline:DictionaryType.AutoCoding
    public required init?(coder aDecoder: NSCoder) {
        guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
        guard let valueTypeName: TypeName = aDecoder.decode(forKey: "valueTypeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["valueTypeName"])); fatalError() }; self.valueTypeName = valueTypeName
        valueType = aDecoder.decode(forKey: "valueType")
        guard let keyTypeName: TypeName = aDecoder.decode(forKey: "keyTypeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["keyTypeName"])); fatalError() }; self.keyTypeName = keyTypeName
        keyType = aDecoder.decode(forKey: "keyType")
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(valueTypeName, forKey: "valueTypeName")
        aCoder.encode(valueType, forKey: "valueType")
        aCoder.encode(keyTypeName, forKey: "keyTypeName")
        aCoder.encode(keyType, forKey: "keyType")
    }
    // sourcery:end
}
