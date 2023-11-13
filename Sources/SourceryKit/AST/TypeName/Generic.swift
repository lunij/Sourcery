import Foundation

/// Descibes Swift generic type
public final class GenericType: Diffable, Equatable, Hashable {
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

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericType else {
            results.append("Incorrect type <expected: GenericType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeParameters").trackDifference(actual: self.typeParameters, expected: castObject.typeParameters))
        return results
    }

    public var description: String {
        asSource
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(typeParameters)
    }

    public static func == (lhs: GenericType, rhs: GenericType) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.typeParameters != rhs.typeParameters { return false }
        return true
    }
}

/// Descibes Swift generic type parameter
public final class GenericTypeParameter: Diffable, Equatable, Hashable, CustomStringConvertible {

    /// Generic parameter type name
    public var typeName: TypeName

    /// Generic parameter type, if known
    public var type: Type?

    public init(typeName: TypeName, type: Type? = nil) {
        self.typeName = typeName
        self.type = type
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericTypeParameter else {
            results.append("Incorrect type <expected: GenericTypeParameter, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "typeName = \(String(describing: typeName))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeName)
    }

    public static func == (lhs: GenericTypeParameter, rhs: GenericTypeParameter) -> Bool {
        if lhs.typeName != rhs.typeName { return false }
        return true
    }
}
