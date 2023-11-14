import Foundation
import Stencil

/// Describes a function parameter
public class FunctionParameter: Diffable, Typed, Annotated, Hashable {
    /// Parameter external name
    public var argumentLabel: String?

    // Note: although method parameter can have no name, this property is not optional,
    // this is so to maintain compatibility with existing templates.
    /// Parameter internal name
    public let name: String

    /// Parameter type name
    public let typeName: TypeName

    /// Parameter flag whether it's inout or not
    public let `inout`: Bool

    /// Is this variadic parameter?
    public let isVariadic: Bool

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
        argumentLabel: String?,
        name: String = "", 
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: NSObject] = [:], 
        isInout: Bool = false,
        isVariadic: Bool = false
    ) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.inout = isInout
        self.isVariadic = isVariadic
    }

    public init(
        name: String = "", 
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: NSObject] = [:],
        isInout: Bool = false,
        isVariadic: Bool = false
    ) {
        self.typeName = typeName
        argumentLabel = name
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.inout = isInout
        self.isVariadic = isVariadic
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? FunctionParameter else {
            results.append("Incorrect type <expected: FunctionParameter, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "argumentLabel").trackDifference(actual: argumentLabel, expected: castObject.argumentLabel))
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "`inout`").trackDifference(actual: self.inout, expected: castObject.inout))
        results.append(contentsOf: DiffableResult(identifier: "isVariadic").trackDifference(actual: isVariadic, expected: castObject.isVariadic))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        return results
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(argumentLabel)
        hasher.combine(name)
        hasher.combine(typeName)
        hasher.combine(`inout`)
        hasher.combine(isVariadic)
        hasher.combine(defaultValue)
        hasher.combine(annotations)
    }

    public static func == (lhs: FunctionParameter, rhs: FunctionParameter) -> Bool {
        lhs.argumentLabel == rhs.argumentLabel
            && lhs.name == rhs.name
            && lhs.typeName == rhs.typeName
            && lhs.inout == rhs.inout
            && lhs.isVariadic == rhs.isVariadic
            && lhs.defaultValue == rhs.defaultValue
            && lhs.annotations == rhs.annotations
    }
}

extension FunctionParameter: CustomStringConvertible {
    public var description: String {
        let typeSuffix = ": \(`inout` ? "inout " : "")\(typeName.asSource)\(defaultValue.map { " = \($0)" } ?? "")" + (isVariadic ? "..." : "")
        guard argumentLabel != name else {
            return name + typeSuffix
        }

        let labels = [argumentLabel ?? "_", name.nilIfEmpty]
            .compactMap { $0 }
            .joined(separator: " ")

        return (labels.nilIfEmpty ?? "_") + typeSuffix
    }
}

extension FunctionParameter: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "actualTypeName": typeName.actualTypeName
        case "annotations": annotations
        case "argumentLabel": argumentLabel
        case "defaultValue": defaultValue
        case "description": description
        case "inout": `inout`
        case "isArray": typeName.isArray
        case "isClosure": typeName.isClosure
        case "isDictionary": typeName.isDictionary
        case "isImplicitlyUnwrappedOptional": typeName.isImplicitlyUnwrappedOptional
        case "isOptional": typeName.isOptional
        case "isTuple": typeName.isTuple
        case "isVariadic": isVariadic
        case "name": name
        case "type": type
        case "typeAttributes": typeAttributes
        case "typeName": typeName
        case "unwrappedTypeName": typeName.unwrappedTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }
}

public extension [FunctionParameter] {
    var asSource: String {
        "(\(map(\.description).joined(separator: ", ")))"
    }
}
