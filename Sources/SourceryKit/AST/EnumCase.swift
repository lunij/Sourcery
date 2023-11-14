import Foundation
import Stencil

/// Defines enum case
public struct EnumCase: Annotated, Documented, Hashable {
    /// Enum case name
    public let name: String

    /// Enum case raw value, if any
    public let rawValue: String?

    /// Enum case associated values
    public let associatedValues: [AssociatedValue]

    /// Enum case annotations
    public let annotations: Annotations

    public let documentation: Documentation

    /// Whether enum case is indirect
    public let indirect: Bool

    /// Whether enum case has associated value
    public var hasAssociatedValue: Bool {
        !associatedValues.isEmpty
    }

    public init(
        name: String,
        rawValue: String? = nil,
        associatedValues: [AssociatedValue] = [],
        annotations: [String: NSObject] = [:],
        documentation: [String] = [],
        indirect: Bool = false
    ) {
        self.name = name
        self.rawValue = rawValue
        self.associatedValues = associatedValues
        self.annotations = annotations
        self.documentation = documentation
        self.indirect = indirect
    }
}

extension EnumCase: Diffable {
    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? EnumCase else {
            results.append("Incorrect type <expected: EnumCase, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "rawValue").trackDifference(actual: rawValue, expected: castObject.rawValue))
        results.append(contentsOf: DiffableResult(identifier: "associatedValues").trackDifference(actual: associatedValues, expected: castObject.associatedValues))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "indirect").trackDifference(actual: indirect, expected: castObject.indirect))
        return results
    }
}

extension EnumCase: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "name": name
        case "rawValue": rawValue
        case "associatedValues": associatedValues
        case "annotations": annotations
        case "documentation": documentation
        case "indirect": indirect
        case "hasAssociatedValue": hasAssociatedValue
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }
}
