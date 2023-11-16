import Foundation
import Stencil

/// Defines enum case associated value
public final class AssociatedValue: Typed, Annotated {
    /// Associated value local name.
    /// This is a name to be used to construct enum case value
    public let localName: String?

    /// Associated value external name.
    /// This is a name to be used to access value in value-bindig
    public let externalName: String?

    /// Associated value type name
    public let typeName: TypeName

    /// Associated value type, if known
    public var type: Type?

    /// Associated value default value
    public let defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public init(
        localName: String?,
        externalName: String?,
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: AnnotationValue] = [:]
    ) {
        self.localName = localName
        self.externalName = externalName
        self.typeName = typeName
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
    }

    convenience init(
        name: String? = nil,
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: AnnotationValue] = [:]
    ) {
        self.init(
            localName: name,
            externalName: name,
            typeName: typeName,
            type: type,
            defaultValue: defaultValue,
            annotations: annotations
        )
    }
}

extension AssociatedValue: CustomStringConvertible {
    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "localName = \(String(describing: localName)), "
        string += "externalName = \(String(describing: externalName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations))"
        return string
    }
}

extension AssociatedValue: Equatable {
    public static func == (lhs: AssociatedValue, rhs: AssociatedValue) -> Bool {
        lhs.localName == rhs.localName
            && lhs.externalName == rhs.externalName
            && lhs.typeName == rhs.typeName
            && lhs.defaultValue == rhs.defaultValue
            && lhs.annotations == rhs.annotations
    }
}

extension AssociatedValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(localName)
        hasher.combine(externalName)
        hasher.combine(typeName)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
    }
}

extension AssociatedValue: Diffable {
    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? AssociatedValue else {
            results.append("Incorrect type <expected: AssociatedValue, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "localName").trackDifference(actual: localName, expected: castObject.localName))
        results.append(contentsOf: DiffableResult(identifier: "externalName").trackDifference(actual: externalName, expected: castObject.externalName))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        return results
    }
}

extension AssociatedValue: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "actualTypeName": typeName.actualTypeName
        case "annotations": annotations
        case "defaultValue": defaultValue
        case "description": description
        case "externalName": externalName
        case "isArray": typeName.isArray
        case "isClosure": typeName.isClosure
        case "isDictionary": typeName.isDictionary
        case "isImplicitlyUnwrappedOptional": typeName.isImplicitlyUnwrappedOptional
        case "isOptional": typeName.isOptional
        case "isTuple": typeName.isTuple
        case "localName": localName
        case "type": type
        case "typeName": typeName
        case "unwrappedTypeName": typeName.unwrappedTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }
}
