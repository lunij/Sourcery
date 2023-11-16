import Foundation
import Stencil

/// Describes function
public final class Function: Annotated, Documented, Definition {
    /// Full function name, including generic constraints, i.e. `foo<T>(bar: T)`
    public let name: String

    /// Method name including arguments names, i.e. `foo(bar:)`
    public var selectorName: String

    /// Method parameters
    public var parameters: [FunctionParameter]

    /// Return value type name used in declaration, including generic constraints, i.e. `where T: Equatable`
    public var returnTypeName: TypeName

    /// Actual return value type, if known
    public var returnType: Type?

    /// Whether function is async function
    public let isAsync: Bool

    /// Whether function throws
    public let `throws`: Bool

    /// Whether function rethrows
    public let `rethrows`: Bool

    /// Method access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    public let accessLevel: String

    /// Whether function is a static function
    public let isStatic: Bool

    /// Whether function is a class function
    public let isClass: Bool

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public let annotations: Annotations

    public let documentation: Documentation

    /// Reference to type name where the function is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc
    public let definedInTypeName: TypeName?

    /// Reference to actual type where the object is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc or type is unknown
    public var definedInType: Type?

    /// Method attributes, i.e. `@discardableResult`
    public let attributes: AttributeList

    /// Method modifiers, i.e. `private`
    public let modifiers: [Modifier]

    /// Method name without arguments names and parenthesis, i.e. `foo<T>`
    public var shortName: String {
        name.range(of: "(").map { String(name[..<$0.lowerBound]) } ?? name
    }

    /// Method name without arguments names, parenthesis and generic types, i.e. `foo` (can be used to generate code for function call)
    public var callName: String {
        shortName.range(of: "<").map { String(shortName[..<$0.lowerBound]) } ?? shortName
    }

    /// Actual return value type name if declaration uses typealias, otherwise just a `returnTypeName`
    public var actualReturnTypeName: TypeName {
        returnTypeName.actualTypeName ?? returnTypeName
    }

    /// Whether return value type is optional
    public var isOptionalReturnType: Bool {
        returnTypeName.isOptional || isFailableInitializer
    }

    /// Whether return value type is implicitly unwrapped optional
    public var isImplicitlyUnwrappedOptionalReturnType: Bool {
        returnTypeName.isImplicitlyUnwrappedOptional
    }

    /// Return value type name without attributes and optional type information
    public var unwrappedReturnTypeName: String {
        returnTypeName.unwrappedTypeName
    }

    /// Whether function is an initializer
    public var isInitializer: Bool {
        selectorName.hasPrefix("init(") || selectorName == "init"
    }

    /// Whether function is an deinitializer
    public var isDeinitializer: Bool {
        selectorName == "deinit"
    }

    /// Whether function is a failable initializer
    public let isFailableInitializer: Bool

    /// Whether function is a convenience initializer
    public var isConvenienceInitializer: Bool {
        modifiers.contains { $0.name == "convenience" }
    }

    /// Whether function is required
    public var isRequired: Bool {
        modifiers.contains { $0.name == "required" }
    }

    /// Whether function is final
    public var isFinal: Bool {
        modifiers.contains { $0.name == "final" }
    }

    /// Whether function is mutating
    public var isMutating: Bool {
        modifiers.contains { $0.name == "mutating" }
    }

    /// Whether function is generic
    public var isGeneric: Bool {
        shortName.hasSuffix(">")
    }

    /// Whether function is optional (in an Objective-C protocol)
    public var isOptional: Bool {
        modifiers.contains { $0.name == "optional" }
    }

    /// Whether function is nonisolated (this modifier only applies to actor functions)
    public var isNonisolated: Bool {
        modifiers.contains { $0.name == "nonisolated" }
    }

    /// Reference to actual type name where the function is defined if declaration uses typealias, otherwise just a `definedInTypeName`
    public var actualDefinedInTypeName: TypeName? {
        definedInTypeName?.actualTypeName ?? definedInTypeName
    }

    public init(
        name: String,
        selectorName: String? = nil,
        parameters: [FunctionParameter] = [],
        returnTypeName: TypeName = TypeName(name: "Void"),
        isAsync: Bool = false,
        throws: Bool = false,
        rethrows: Bool = false,
        accessLevel: AccessLevel = .internal,
        isStatic: Bool = false,
        isClass: Bool = false,
        isFailableInitializer: Bool = false,
        attributes: AttributeList = [:],
        modifiers: [Modifier] = [],
        annotations: [String: AnnotationValue] = [:],
        documentation: [String] = [],
        definedInTypeName: TypeName? = nil
    ) {
        self.name = name
        self.selectorName = selectorName ?? name
        self.parameters = parameters
        self.returnTypeName = returnTypeName
        self.isAsync = isAsync
        self.throws = `throws`
        self.rethrows = `rethrows`
        self.accessLevel = accessLevel.rawValue
        self.isStatic = isStatic
        self.isClass = isClass
        self.isFailableInitializer = isFailableInitializer
        self.attributes = attributes
        self.modifiers = modifiers
        self.annotations = annotations
        self.documentation = documentation
        self.definedInTypeName = definedInTypeName
    }
}

extension Function: Diffable {
    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Function else {
            results.append("Incorrect type <expected: Method, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "selectorName").trackDifference(actual: selectorName, expected: castObject.selectorName))
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.throws, expected: castObject.throws))
        results.append(contentsOf: DiffableResult(identifier: "`rethrows`").trackDifference(actual: self.rethrows, expected: castObject.rethrows))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "isStatic").trackDifference(actual: isStatic, expected: castObject.isStatic))
        results.append(contentsOf: DiffableResult(identifier: "isClass").trackDifference(actual: isClass, expected: castObject.isClass))
        results.append(contentsOf: DiffableResult(identifier: "isFailableInitializer").trackDifference(actual: isFailableInitializer, expected: castObject.isFailableInitializer))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: definedInTypeName, expected: castObject.definedInTypeName))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: modifiers, expected: castObject.modifiers))
        return results
    }
}

extension Function: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "accessLevel": accessLevel
        case "actualDefinedInTypeName": actualDefinedInTypeName
        case "actualReturnTypeName": actualReturnTypeName
        case "annotations": annotations
        case "attributes": attributes
        case "callName": callName
        case "definedInType": definedInType
        case "definedInTypeName": definedInTypeName
        case "documentation": documentation
        case "isAsync": isAsync
        case "isClass": isClass
        case "isConvenienceInitializer": isConvenienceInitializer
        case "isDeinitializer": isDeinitializer
        case "isFailableInitializer": isFailableInitializer
        case "isFinal": isFinal
        case "isGeneric": isGeneric
        case "isImplicitlyUnwrappedOptionalReturnType": isImplicitlyUnwrappedOptionalReturnType
        case "isInitializer": isInitializer
        case "isMutating": isMutating
        case "isNonisolated": isNonisolated
        case "isOptional": isOptional
        case "isOptionalReturnType": isOptionalReturnType
        case "isRequired": isRequired
        case "isStatic": isStatic
        case "modifiers": modifiers
        case "name": name
        case "parameters": parameters
        case "rethrows": `rethrows`
        case "returnType": returnType
        case "returnTypeName": returnTypeName
        case "selectorName": selectorName
        case "shortName": shortName
        case "throws": `throws`
        case "unwrappedReturnTypeName": unwrappedReturnTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }
}

extension Function: Equatable {
    public static func == (lhs: Function, rhs: Function) -> Bool {
        lhs.name == rhs.name
            && lhs.selectorName == rhs.selectorName
            && lhs.parameters == rhs.parameters
            && lhs.returnTypeName == rhs.returnTypeName
            && lhs.isAsync == rhs.isAsync
            && lhs.throws == rhs.throws
            && lhs.rethrows == rhs.rethrows
            && lhs.accessLevel == rhs.accessLevel
            && lhs.isStatic == rhs.isStatic
            && lhs.isClass == rhs.isClass
            && lhs.isFailableInitializer == rhs.isFailableInitializer
            && lhs.annotations == rhs.annotations
            && lhs.documentation == rhs.documentation
            && lhs.definedInTypeName == rhs.definedInTypeName
            && lhs.attributes == rhs.attributes
            && lhs.modifiers == rhs.modifiers
    }
}

extension Function: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(selectorName)
        hasher.combine(parameters)
        hasher.combine(returnTypeName)
        hasher.combine(isAsync)
        hasher.combine(`throws`)
        hasher.combine(`rethrows`)
        hasher.combine(accessLevel)
        hasher.combine(isStatic)
        hasher.combine(isClass)
        hasher.combine(isFailableInitializer)
        hasher.combine(annotations)
        hasher.combine(documentation)
        hasher.combine(definedInTypeName)
        hasher.combine(attributes)
        hasher.combine(modifiers)
    }
}
