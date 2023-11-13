import Foundation

/// modifier can be thing like `private`, `class`, `nonmutating`
/// if a declaration has modifier like `private(set)` it's name will be `private` and detail will be `set`
public class GenericRequirement: Diffable, Equatable, Hashable, CustomStringConvertible {

    public enum Relationship: String {
        case equals
        case conformsTo

        var syntax: String {
            switch self {
            case .equals:
                return "=="
            case .conformsTo:
                return ":"
            }
        }
    }

    public var leftType: AssociatedType
    public let rightType: GenericTypeParameter

    /// relationship name
    public let relationship: String

    /// Syntax e.g. `==` or `:`
    public let relationshipSyntax: String

    public init(leftType: AssociatedType, rightType: GenericTypeParameter, relationship: Relationship) {
        self.leftType = leftType
        self.rightType = rightType
        self.relationship = relationship.rawValue
        self.relationshipSyntax = relationship.syntax
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? GenericRequirement else {
            results.append("Incorrect type <expected: GenericRequirement, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "leftType").trackDifference(actual: self.leftType, expected: castObject.leftType))
        results.append(contentsOf: DiffableResult(identifier: "rightType").trackDifference(actual: self.rightType, expected: castObject.rightType))
        results.append(contentsOf: DiffableResult(identifier: "relationship").trackDifference(actual: self.relationship, expected: castObject.relationship))
        results.append(contentsOf: DiffableResult(identifier: "relationshipSyntax").trackDifference(actual: self.relationshipSyntax, expected: castObject.relationshipSyntax))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "leftType = \(String(describing: leftType)), "
        string += "rightType = \(String(describing: rightType)), "
        string += "relationship = \(String(describing: relationship)), "
        string += "relationshipSyntax = \(String(describing: relationshipSyntax))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(leftType)
        hasher.combine(rightType)
        hasher.combine(relationship)
        hasher.combine(relationshipSyntax)
    }

    public static func == (lhs: GenericRequirement, rhs: GenericRequirement) -> Bool {
        if lhs.leftType != rhs.leftType { return false }
        if lhs.rightType != rhs.rightType { return false }
        if lhs.relationship != rhs.relationship { return false }
        if lhs.relationshipSyntax != rhs.relationshipSyntax { return false }
        return true
    }
}
