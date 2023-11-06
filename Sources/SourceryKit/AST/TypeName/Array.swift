import Foundation

/// Describes array type
@objcMembers public final class ArrayType: NSObject, SourceryModel {

    /// Type name used in declaration
    public var name: String

    /// Array element type name
    public var elementTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Array element type, if known
    public var elementType: Type?

    /// :nodoc:
    public init(name: String, elementTypeName: TypeName, elementType: Type? = nil) {
        self.name = name
        self.elementTypeName = elementTypeName
        self.elementType = elementType
    }

    /// Returns array as generic type
    public var asGeneric: GenericType {
        GenericType(name: "Array", typeParameters: [
            .init(typeName: elementTypeName)
        ])
    }

    public var asSource: String {
        "[\(elementTypeName.asSource)]"
    }
}
