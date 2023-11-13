import Foundation

/// Describes Swift attribute
public struct Attribute: Hashable {
    /// Attribute name
    public let name: String

    /// Attribute arguments
    public let arguments: [String]

    public init(name: String, arguments: [String] = []) {
        self.name = name
        self.arguments = arguments
    }
}

extension Attribute: CustomStringConvertible {
    public var description: String {
        let argumentsDescription = arguments.map(\.description).joined(separator: ", ")
        return argumentsDescription.isEmpty ? "@\(name)" : "@\(name)(\(argumentsDescription))"
    }
}

extension Attribute: Diffable {
    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Attribute else {
            results.append("Incorrect type <expected: Attribute, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "arguments").trackDifference(actual: arguments, expected: castObject.arguments))
        return results
    }
}

public typealias AttributeList = [String: [Attribute]]
