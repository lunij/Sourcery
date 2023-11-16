import Foundation
import Stencil

public final class ClosureParameter: Typed, Annotated {
    /// Parameter external name
    public var argumentLabel: String?

    /// Parameter internal name
    public let name: String?

    /// Parameter type name
    public let typeName: TypeName

    /// Parameter flag whether it's inout or not
    public let isInout: Bool

    // sourcery: skipEquality, skipDescription
    /// Parameter type, if known
    public var type: Type?

    /// Parameter type attributes, i.e. `@escaping`
    public var typeAttributes: AttributeList {
        typeName.attributes
    }

    /// Method parameter default value expression
    public var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public init(
        argumentLabel: String? = nil,
        name: String? = nil,
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: AnnotationValue] = [:],
        isInout: Bool = false
    ) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.isInout = isInout
    }
}

extension ClosureParameter: CustomStringConvertible {
    public var description: String {
        let typeInfo = "\(isInout ? "inout " : "")\(typeName.asSource)"
        if argumentLabel?.nilIfNotValidParameterName == nil, name?.nilIfNotValidParameterName == nil {
            return typeInfo
        }

        let typeSuffix = ": \(typeInfo)"
        guard argumentLabel != name else {
            return name ?? "" + typeSuffix
        }

        let labels = [argumentLabel ?? "_", name?.nilIfEmpty]
            .compactMap { $0 }
            .joined(separator: " ")

        return (labels.nilIfEmpty ?? "_") + typeSuffix
    }
}

extension ClosureParameter: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "actualTypeName": typeName.actualTypeName
        case "isArray": typeName.isArray
        case "isClosure": typeName.isClosure
        case "isDictionary": typeName.isDictionary
        case "isImplicitlyUnwrappedOptional": typeName.isImplicitlyUnwrappedOptional
        case "isOptional": typeName.isOptional
        case "isTuple": typeName.isTuple
        case "unwrappedTypeName": typeName.unwrappedTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }
}

extension ClosureParameter: Equatable {
    public static func == (lhs: ClosureParameter, rhs: ClosureParameter) -> Bool {
        lhs.argumentLabel == rhs.argumentLabel
            && lhs.name == rhs.name
            && lhs.typeName == rhs.typeName
            && lhs.isInout == rhs.isInout
            && lhs.defaultValue == rhs.defaultValue
            && lhs.annotations == rhs.annotations
    }
}

extension ClosureParameter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(argumentLabel)
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(isInout)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
    }
}

public extension [ClosureParameter] {
    var asSource: String {
        "(\(map(\.description).joined(separator: ", ")))"
    }
}
