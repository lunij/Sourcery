import Foundation

/// Descibes Swift generic type
@objcMembers public final class GenericType: NSObject, SourceryModelWithoutDescription {
    /// The name of the base type, i.e. `Array` for `Array<Int>`
    public var name: String

    /// This generic type parameters
    public let typeParameters: [GenericTypeParameter]

    public init(name: String, typeParameters: [GenericTypeParameter] = []) {
        self.name = name
        self.typeParameters = typeParameters
    }

    public var asSource: String {
        let arguments = typeParameters
          .map({ $0.typeName.asSource })
          .joined(separator: ", ")
        return "\(name)<\(arguments)>"
    }

    public override var description: String {
        asSource
    }
}

/// Descibes Swift generic type parameter
@objcMembers public final class GenericTypeParameter: NSObject, SourceryModel {

    /// Generic parameter type name
    public var typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Generic parameter type, if known
    public var type: Type?

    public init(typeName: TypeName, type: Type? = nil) {
        self.typeName = typeName
        self.type = type
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "typeName = \(String(describing: typeName))"
        return string
    }
}
