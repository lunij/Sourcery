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

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "elementTypeName = \(String(describing: elementTypeName)), "
        string += "asGeneric = \(String(describing: asGeneric)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}
