import DynamicMemberLookup
import Foundation

public typealias SourceryMethod = Method

/// Describes method parameter
@DynamicMemberLookup
@objcMembers public class MethodParameter: NSObject, Diffable, Typed, Annotated {
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
        return typeName.attributes
    }

    /// Method parameter default value expression
    public var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public init(argumentLabel: String?, name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:], isInout: Bool = false, isVariadic: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.`inout` = isInout
        self.isVariadic = isVariadic
    }

    public init(name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:], isInout: Bool = false, isVariadic: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = name
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.`inout` = isInout
        self.isVariadic = isVariadic
    }

    public var asSource: String {
        let typeSuffix = ": \(`inout` ? "inout " : "")\(typeName.asSource)\(defaultValue.map { " = \($0)" } ?? "")" + (isVariadic ? "..." : "")
        guard argumentLabel != name else {
            return name + typeSuffix
        }

        let labels = [argumentLabel ?? "_", name.nilIfEmpty]
          .compactMap { $0 }
          .joined(separator: " ")

        return (labels.nilIfEmpty ?? "_") + typeSuffix
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? MethodParameter else {
            results.append("Incorrect type <expected: MethodParameter, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "argumentLabel").trackDifference(actual: self.argumentLabel, expected: castObject.argumentLabel))
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "`inout`").trackDifference(actual: self.`inout`, expected: castObject.`inout`))
        results.append(contentsOf: DiffableResult(identifier: "isVariadic").trackDifference(actual: self.isVariadic, expected: castObject.isVariadic))
        results.append(contentsOf: DiffableResult(identifier: "defaultValue").trackDifference(actual: self.defaultValue, expected: castObject.defaultValue))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: self.annotations, expected: castObject.annotations))
        return results
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "argumentLabel = \(String(describing: argumentLabel)), "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "`inout` = \(String(describing: `inout`)), "
        string += "isVariadic = \(String(describing: isVariadic)), "
        string += "typeAttributes = \(String(describing: typeAttributes)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

extension Array where Element == MethodParameter {
    public var asSource: String {
        "(\(map { $0.asSource }.joined(separator: ", ")))"
    }
}

// sourcery: skipDiffing
@objcMembers public final class ClosureParameter: NSObject, Typed, Annotated {
    /// Parameter external name
    public var argumentLabel: String?

    /// Parameter internal name
    public let name: String?

    /// Parameter type name
    public let typeName: TypeName

    /// Parameter flag whether it's inout or not
    public let `inout`: Bool

    // sourcery: skipEquality, skipDescription
    /// Parameter type, if known
    public var type: Type?

    /// Parameter type attributes, i.e. `@escaping`
    public var typeAttributes: AttributeList {
        return typeName.attributes
    }

    /// Method parameter default value expression
    public var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    public init(argumentLabel: String? = nil, name: String? = nil, typeName: TypeName, type: Type? = nil,
                defaultValue: String? = nil, annotations: [String: NSObject] = [:], isInout: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.`inout` = isInout
    }

    public var asSource: String {
        let typeInfo = "\(`inout` ? "inout " : "")\(typeName.asSource)"
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

    override public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "argumentLabel = \(String(describing: argumentLabel)), "
        string += "name = \(String(describing: name)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "`inout` = \(String(describing: `inout`)), "
        string += "typeAttributes = \(String(describing: typeAttributes)), "
        string += "defaultValue = \(String(describing: defaultValue)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }
}

extension Array where Element == ClosureParameter {
    public var asSource: String {
        "(\(map { $0.asSource }.joined(separator: ", ")))"
    }
}

/// Describes method
@DynamicMemberLookup
@objc(SwiftMethod) @objcMembers public final class Method: NSObject, Annotated, Diffable, Documented, Definition {

    /// Full method name, including generic constraints, i.e. `foo<T>(bar: T)`
    public let name: String

    /// Method name including arguments names, i.e. `foo(bar:)`
    public var selectorName: String

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names and parenthesis, i.e. `foo<T>`
    public var shortName: String {
        return name.range(of: "(").map({ String(name[..<$0.lowerBound]) }) ?? name
    }

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names, parenthesis and generic types, i.e. `foo` (can be used to generate code for method call)
    public var callName: String {
        return shortName.range(of: "<").map({ String(shortName[..<$0.lowerBound]) }) ?? shortName
    }

    /// Method parameters
    public var parameters: [MethodParameter]

    /// Return value type name used in declaration, including generic constraints, i.e. `where T: Equatable`
    public var returnTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Actual return value type name if declaration uses typealias, otherwise just a `returnTypeName`
    public var actualReturnTypeName: TypeName {
        return returnTypeName.actualTypeName ?? returnTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Actual return value type, if known
    public var returnType: Type?

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is optional
    public var isOptionalReturnType: Bool {
        return returnTypeName.isOptional || isFailableInitializer
    }

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is implicitly unwrapped optional
    public var isImplicitlyUnwrappedOptionalReturnType: Bool {
        return returnTypeName.isImplicitlyUnwrappedOptional
    }

    // sourcery: skipEquality, skipDescription
    /// Return value type name without attributes and optional type information
    public var unwrappedReturnTypeName: String {
        return returnTypeName.unwrappedTypeName
    }

    /// Whether method is async method
    public let isAsync: Bool

    /// Whether method throws
    public let `throws`: Bool

    /// Whether method rethrows
    public let `rethrows`: Bool

    /// Method access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    public let accessLevel: String

    /// Whether method is a static method
    public let isStatic: Bool

    /// Whether method is a class method
    public let isClass: Bool

    // sourcery: skipEquality, skipDescription
    /// Whether method is an initializer
    public var isInitializer: Bool {
        return selectorName.hasPrefix("init(") || selectorName == "init"
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is an deinitializer
    public var isDeinitializer: Bool {
        return selectorName == "deinit"
    }

    /// Whether method is a failable initializer
    public let isFailableInitializer: Bool

    // sourcery: skipEquality, skipDescription
    /// Whether method is a convenience initializer
    public var isConvenienceInitializer: Bool {
        modifiers.contains { $0.name == "convenience" }
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is required
    public var isRequired: Bool {
        modifiers.contains { $0.name == "required" }
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is final
    public var isFinal: Bool {
        modifiers.contains { $0.name == "final" }
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is mutating
    public var isMutating: Bool {
        modifiers.contains { $0.name == "mutating" }
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is generic
    public var isGeneric: Bool {
        shortName.hasSuffix(">")
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is optional (in an Objective-C protocol)
    public var isOptional: Bool {
        modifiers.contains { $0.name == "optional" }
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is nonisolated (this modifier only applies to actor methods)
    public var isNonisolated: Bool {
        modifiers.contains { $0.name == "nonisolated" }
    }

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public let annotations: Annotations

    public let documentation: Documentation

    /// Reference to type name where the method is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc
    public let definedInTypeName: TypeName?

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type name where the method is defined if declaration uses typealias, otherwise just a `definedInTypeName`
    public var actualDefinedInTypeName: TypeName? {
        return definedInTypeName?.actualTypeName ?? definedInTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type where the object is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc or type is unknown
    public var definedInType: Type?

    /// Method attributes, i.e. `@discardableResult`
    public let attributes: AttributeList

    /// Method modifiers, i.e. `private`
    public let modifiers: [SourceryModifier]

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding
    public var __parserData: Any?

    public init(name: String,
                selectorName: String? = nil,
                parameters: [MethodParameter] = [],
                returnTypeName: TypeName = TypeName(name: "Void"),
                isAsync: Bool = false,
                throws: Bool = false,
                rethrows: Bool = false,
                accessLevel: AccessLevel = .internal,
                isStatic: Bool = false,
                isClass: Bool = false,
                isFailableInitializer: Bool = false,
                attributes: AttributeList = [:],
                modifiers: [SourceryModifier] = [],
                annotations: [String: NSObject] = [:],
                documentation: [String] = [],
                definedInTypeName: TypeName? = nil) {

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

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Method else {
            results.append("Incorrect type <expected: Method, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "selectorName").trackDifference(actual: self.selectorName, expected: castObject.selectorName))
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: self.parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: self.returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: self.isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.`throws`, expected: castObject.`throws`))
        results.append(contentsOf: DiffableResult(identifier: "`rethrows`").trackDifference(actual: self.`rethrows`, expected: castObject.`rethrows`))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: self.accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "isStatic").trackDifference(actual: self.isStatic, expected: castObject.isStatic))
        results.append(contentsOf: DiffableResult(identifier: "isClass").trackDifference(actual: self.isClass, expected: castObject.isClass))
        results.append(contentsOf: DiffableResult(identifier: "isFailableInitializer").trackDifference(actual: self.isFailableInitializer, expected: castObject.isFailableInitializer))
        results.append(contentsOf: DiffableResult(identifier: "annotations").trackDifference(actual: self.annotations, expected: castObject.annotations))
        results.append(contentsOf: DiffableResult(identifier: "documentation").trackDifference(actual: self.documentation, expected: castObject.documentation))
        results.append(contentsOf: DiffableResult(identifier: "definedInTypeName").trackDifference(actual: self.definedInTypeName, expected: castObject.definedInTypeName))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: self.attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: self.modifiers, expected: castObject.modifiers))
        return results
    }

    override public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "selectorName = \(String(describing: selectorName)), "
        string += "parameters = \(String(describing: parameters)), "
        string += "returnTypeName = \(String(describing: returnTypeName)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "`throws` = \(String(describing: `throws`)), "
        string += "`rethrows` = \(String(describing: `rethrows`)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "isStatic = \(String(describing: isStatic)), "
        string += "isClass = \(String(describing: isClass)), "
        string += "isFailableInitializer = \(String(describing: isFailableInitializer)), "
        string += "annotations = \(String(describing: annotations)), "
        string += "documentation = \(String(describing: documentation)), "
        string += "definedInTypeName = \(String(describing: definedInTypeName)), "
        string += "attributes = \(String(describing: attributes)), "
        string += "modifiers = \(String(describing: modifiers))"
        return string
    }
}
