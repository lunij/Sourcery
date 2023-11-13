import Foundation

/// Describes array type
public final class ArrayType: Diffable, Equatable, Hashable, CustomStringConvertible {

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

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? ArrayType else {
            results.append("Incorrect type <expected: ArrayType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "elementTypeName").trackDifference(actual: self.elementTypeName, expected: castObject.elementTypeName))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "elementTypeName = \(String(describing: elementTypeName)), "
        string += "asGeneric = \(String(describing: asGeneric)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(elementTypeName)
    }

    public static func == (lhs: ArrayType, rhs: ArrayType) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.elementTypeName != rhs.elementTypeName { return false }
        return true
    }
}
