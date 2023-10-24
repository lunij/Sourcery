import Foundation

/// :nodoc:
public typealias SourceryMethod = Method

/// Describes method parameter
@objcMembers public class MethodParameter: NSObject, SourceryModel, Typed, Annotated {
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

    /// :nodoc:
    public init(argumentLabel: String?, name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:], isInout: Bool = false, isVariadic: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.inout = isInout
        self.isVariadic = isVariadic
    }

    /// :nodoc:
    public init(name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: [String: NSObject] = [:], isInout: Bool = false, isVariadic: Bool = false) {
        self.typeName = typeName
        argumentLabel = name
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.inout = isInout
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

    // sourcery:inline:MethodParameter.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        argumentLabel = aDecoder.decode(forKey: "argumentLabel")
        guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
        guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
        `inout` = aDecoder.decode(forKey: "`inout`")
        isVariadic = aDecoder.decode(forKey: "isVariadic")
        type = aDecoder.decode(forKey: "type")
        defaultValue = aDecoder.decode(forKey: "defaultValue")
        guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(argumentLabel, forKey: "argumentLabel")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(typeName, forKey: "typeName")
        aCoder.encode(`inout`, forKey: "`inout`")
        aCoder.encode(isVariadic, forKey: "isVariadic")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(defaultValue, forKey: "defaultValue")
        aCoder.encode(annotations, forKey: "annotations")
    }
    // sourcery:end
}

public extension [MethodParameter] {
    var asSource: String {
        "(\(map(\.asSource).joined(separator: ", ")))"
    }
}

// sourcery: skipDiffing
@objcMembers public final class ClosureParameter: NSObject, SourceryModel, Typed, Annotated {
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
        typeName.attributes
    }

    /// Method parameter default value expression
    public var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    public var annotations: Annotations = [:]

    /// :nodoc:
    public init(
        argumentLabel: String? = nil,
        name: String? = nil,
        typeName: TypeName,
        type: Type? = nil,
        defaultValue: String? = nil,
        annotations: [String: NSObject] = [:],
        isInout: Bool = false
    ) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.inout = isInout
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

    // sourcery:inline:ClosureParameter.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        argumentLabel = aDecoder.decode(forKey: "argumentLabel")
        name = aDecoder.decode(forKey: "name")
        guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
        `inout` = aDecoder.decode(forKey: "`inout`")
        type = aDecoder.decode(forKey: "type")
        defaultValue = aDecoder.decode(forKey: "defaultValue")
        guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(argumentLabel, forKey: "argumentLabel")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(typeName, forKey: "typeName")
        aCoder.encode(`inout`, forKey: "`inout`")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(defaultValue, forKey: "defaultValue")
        aCoder.encode(annotations, forKey: "annotations")
    }

    // sourcery:end
}

public extension [ClosureParameter] {
    var asSource: String {
        "(\(map(\.asSource).joined(separator: ", ")))"
    }
}

/// Describes method
@objc(SwiftMethod) @objcMembers public final class Method: NSObject, SourceryModel, Annotated, Documented, Definition {
    /// Full method name, including generic constraints, i.e. `foo<T>(bar: T)`
    public let name: String

    /// Method name including arguments names, i.e. `foo(bar:)`
    public var selectorName: String

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names and parenthesis, i.e. `foo<T>`
    public var shortName: String {
        name.range(of: "(").map { String(name[..<$0.lowerBound]) } ?? name
    }

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names, parenthesis and generic types, i.e. `foo` (can be used to generate code for method call)
    public var callName: String {
        shortName.range(of: "<").map { String(shortName[..<$0.lowerBound]) } ?? shortName
    }

    /// Method parameters
    public var parameters: [MethodParameter]

    /// Return value type name used in declaration, including generic constraints, i.e. `where T: Equatable`
    public var returnTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Actual return value type name if declaration uses typealias, otherwise just a `returnTypeName`
    public var actualReturnTypeName: TypeName {
        returnTypeName.actualTypeName ?? returnTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Actual return value type, if known
    public var returnType: Type?

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is optional
    public var isOptionalReturnType: Bool {
        returnTypeName.isOptional || isFailableInitializer
    }

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is implicitly unwrapped optional
    public var isImplicitlyUnwrappedOptionalReturnType: Bool {
        returnTypeName.isImplicitlyUnwrappedOptional
    }

    // sourcery: skipEquality, skipDescription
    /// Return value type name without attributes and optional type information
    public var unwrappedReturnTypeName: String {
        returnTypeName.unwrappedTypeName
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
        selectorName.hasPrefix("init(") || selectorName == "init"
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is an deinitializer
    public var isDeinitializer: Bool {
        selectorName == "deinit"
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
        definedInTypeName?.actualTypeName ?? definedInTypeName
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
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    public var __parserData: Any?

    /// :nodoc:
    public init(
        name: String,
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

    // sourcery:inline:Method.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
        guard let selectorName: String = aDecoder.decode(forKey: "selectorName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["selectorName"])); fatalError() }; self.selectorName = selectorName
        guard let parameters: [MethodParameter] = aDecoder.decode(forKey: "parameters") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["parameters"])); fatalError() }; self.parameters = parameters
        guard let returnTypeName: TypeName = aDecoder.decode(forKey: "returnTypeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["returnTypeName"])); fatalError() }; self.returnTypeName = returnTypeName
        returnType = aDecoder.decode(forKey: "returnType")
        isAsync = aDecoder.decode(forKey: "isAsync")
        `throws` = aDecoder.decode(forKey: "`throws`")
        `rethrows` = aDecoder.decode(forKey: "`rethrows`")
        guard let accessLevel: String = aDecoder.decode(forKey: "accessLevel") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["accessLevel"])); fatalError() }; self.accessLevel = accessLevel
        isStatic = aDecoder.decode(forKey: "isStatic")
        isClass = aDecoder.decode(forKey: "isClass")
        isFailableInitializer = aDecoder.decode(forKey: "isFailableInitializer")
        guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
        guard let documentation: Documentation = aDecoder.decode(forKey: "documentation") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["documentation"])); fatalError() }; self.documentation = documentation
        definedInTypeName = aDecoder.decode(forKey: "definedInTypeName")
        definedInType = aDecoder.decode(forKey: "definedInType")
        guard let attributes: AttributeList = aDecoder.decode(forKey: "attributes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["attributes"])); fatalError() }; self.attributes = attributes
        guard let modifiers: [SourceryModifier] = aDecoder.decode(forKey: "modifiers") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["modifiers"])); fatalError() }; self.modifiers = modifiers
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(selectorName, forKey: "selectorName")
        aCoder.encode(parameters, forKey: "parameters")
        aCoder.encode(returnTypeName, forKey: "returnTypeName")
        aCoder.encode(returnType, forKey: "returnType")
        aCoder.encode(isAsync, forKey: "isAsync")
        aCoder.encode(`throws`, forKey: "`throws`")
        aCoder.encode(`rethrows`, forKey: "`rethrows`")
        aCoder.encode(accessLevel, forKey: "accessLevel")
        aCoder.encode(isStatic, forKey: "isStatic")
        aCoder.encode(isClass, forKey: "isClass")
        aCoder.encode(isFailableInitializer, forKey: "isFailableInitializer")
        aCoder.encode(annotations, forKey: "annotations")
        aCoder.encode(documentation, forKey: "documentation")
        aCoder.encode(definedInTypeName, forKey: "definedInTypeName")
        aCoder.encode(definedInType, forKey: "definedInType")
        aCoder.encode(attributes, forKey: "attributes")
        aCoder.encode(modifiers, forKey: "modifiers")
    }
    // sourcery:end
}
