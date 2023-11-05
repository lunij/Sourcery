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
}
