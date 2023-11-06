import Foundation

/// modifier can be thing like `private`, `class`, `nonmutating`
/// if a declaration has modifier like `private(set)` it's name will be `private` and detail will be `set`
@objcMembers public class GenericRequirement: NSObject, SourceryModel {

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
}
