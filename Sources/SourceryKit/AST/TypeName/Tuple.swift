import Foundation

/// Describes tuple type
@objcMembers public final class TupleType: NSObject, Diffable {

    /// Type name used in declaration
    public var name: String

    /// Tuple elements
    public var elements: [TupleElement]

    public init(name: String, elements: [TupleElement]) {
        self.name = name
        self.elements = elements
    }

    public init(elements: [TupleElement]) {
        self.name = elements.asSource
        self.elements = elements
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TupleType else {
            results.append("Incorrect type <expected: TupleType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "elements").trackDifference(actual: self.elements, expected: castObject.elements))
        return results
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "elements = \(String(describing: elements))"
        return string
    }
}

/// Describes tuple type element
@objcMembers public final class TupleElement: NSObject, Diffable, Typed {

    /// Tuple element name
    public let name: String?

    /// Tuple element type name
    public var typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Tuple element type, if known
    public var type: Type?

    public init(name: String? = nil, typeName: TypeName, type: Type? = nil) {
        self.name = name
        self.typeName = typeName
        self.type = type
    }

    public var asSource: String {
        // swiftlint:disable:next force_unwrapping
        "\(name != nil ? "\(name!): " : "")\(typeName.asSource)"
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TupleElement else {
            results.append("Incorrect type <expected: TupleElement, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        return results
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "asSource = \(String(describing: asSource))"
        return string
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
