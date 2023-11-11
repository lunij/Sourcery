import Foundation
import SwiftSyntax

extension GenericRequirement {
    convenience init(_ node: SameTypeRequirementSyntax) {
        let leftType = node.leftType.description.trimmed
        let rightType = TypeName(node.rightType.description.trimmed)
        self.init(leftType: .init(name: leftType), rightType: .init(typeName: rightType), relationship: .equals)
    }

    convenience init(_ node: ConformanceRequirementSyntax) {
        let leftType = node.leftType.description.trimmed
        let rightType = TypeName(node.rightType.description.trimmed)
        self.init(leftType: .init(name: leftType), rightType: .init(typeName: rightType), relationship: .conformsTo)
    }
}
