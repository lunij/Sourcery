import Foundation
import Stencil

// sourcery: skipCoding
public final class TemplateContext: Diffable, Equatable, Hashable, CustomStringConvertible {
    public let functions: [Function]
    public let types: Types
    public let argument: [String: AnnotationValue]

    // sourcery: skipDescription
    public var type: [String: Type] {
        return types.typesByName
    }

    public init(types: Types, functions: [Function], arguments: [String: AnnotationValue]) {
        self.types = types
        self.functions = functions
        self.argument = arguments
    }

    public var stencilContext: [String: Any] {
        return [
            "types": types,
            "functions": functions,
            "type": types.typesByName,
            "argument": argument
        ]
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TemplateContext else {
            results.append("Incorrect type <expected: TemplateContext, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "functions").trackDifference(actual: self.functions, expected: castObject.functions))
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: self.types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "argument").trackDifference(actual: self.argument, expected: castObject.argument))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "functions = \(String(describing: functions)), "
        string += "types = \(String(describing: types)), "
        string += "argument = \(String(describing: argument)), "
        string += "stencilContext = \(String(describing: stencilContext))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(functions)
        hasher.combine(types)
        hasher.combine(argument)
    }

    public static func == (lhs: TemplateContext, rhs: TemplateContext) -> Bool {
        lhs.functions == rhs.functions
            && lhs.types == rhs.types
            && lhs.argument == rhs.argument
    }

    enum Error: Swift.Error, Equatable {
        case notAClass(String)
        case notAProtocol(String)
        case unknownType(String)
    }
}

extension TemplateContext.Error: CustomStringConvertible {
    var description: String {
        switch self {
        case let .notAClass(typeName):
            "\(typeName) is not a class and should be used with `implementing` or `based`"
        case let .notAProtocol(typeName):
            "\(typeName) is a class and should be used with `inheriting` or `based`"
        case let .unknownType(typeName):
            "Unknown type \(typeName), should be used with `based`"
        }
    }
}

/// Collection of scanned types for accessing in templates
public final class Types: Diffable, Equatable, Hashable, CustomStringConvertible, DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "all": all
        case "based": based
        case "classes": classes
        case "enums": enums
        case "extensions": extensions
        case "implementing": implementing
        case "inheriting": inheriting
        case "protocols": protocols
        case "structs": structs
        case "types": types
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }

    public let types: [Type]

    /// All known typealiases
    public let typealiases: [Typealias]

    public init(types: [Type], typealiases: [Typealias] = []) {
        self.types = types
        self.typealiases = typealiases
    }

    // sourcery: skipDescription, skipEquality, skipCoding
    public lazy internal(set) var typesByName: [String: Type] = {
        var typesByName = [String: Type]()
        self.types.forEach { typesByName[$0.globalName] = $0 }
        return typesByName
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    public lazy internal(set) var typesaliasesByName: [String: Typealias] = {
        var typesaliasesByName = [String: Typealias]()
        self.typealiases.forEach { typesaliasesByName[$0.name] = $0 }
        return typesaliasesByName
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known types, excluding protocols or protocol compositions.
    public lazy internal(set) var all: [Type] = {
        return self.types.filter { !($0 is Protocol || $0 is ProtocolComposition) }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known protocols
    public lazy internal(set) var protocols: [Protocol] = {
        return self.types.compactMap { $0 as? Protocol }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known protocol compositions
    public lazy internal(set) var protocolCompositions: [ProtocolComposition] = {
        return self.types.compactMap { $0 as? ProtocolComposition }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known classes
    public lazy internal(set) var classes: [Class] = {
        return self.all.compactMap { $0 as? Class }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known structs
    public lazy internal(set) var structs: [Struct] = {
        return self.all.compactMap { $0 as? Struct }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known enums
    public lazy internal(set) var enums: [Enum] = {
        return self.all.compactMap { $0 as? Enum }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known extensions
    public lazy internal(set) var extensions: [Type] = {
        return self.all.compactMap { $0.isExtension ? $0 : nil }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Types based on any other type, grouped by its name, even if they are not known.
    /// `types.based.MyType` returns list of types based on `MyType`
    public lazy internal(set) var based: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.based.keys) }
        )
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Classes inheriting from any known class, grouped by its name.
    /// `types.inheriting.MyClass` returns list of types inheriting from `MyClass`
    public lazy internal(set) var inheriting: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.inherits.keys) },
            validate: { type in
                guard type is Class else {
                    throw TemplateContext.Error.notAClass(type.name)
                }
            })
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Types implementing known protocol, grouped by its name.
    /// `types.implementing.MyProtocol` returns list of types implementing `MyProtocol`
    public lazy internal(set) var implementing: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.implements.keys) },
            validate: { type in
                guard type is Protocol else {
                    throw TemplateContext.Error.notAProtocol(type.name)
                }
            }
        )
    }()

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Types else {
            results.append("Incorrect type <expected: Types, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: self.types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "typealiases").trackDifference(actual: self.typealiases, expected: castObject.typealiases))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "types = \(String(describing: types)), "
        string += "typealiases = \(String(describing: typealiases))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(types)
        hasher.combine(typealiases)
    }

    public static func == (lhs: Types, rhs: Types) -> Bool {
        lhs.types == rhs.types && lhs.typealiases == rhs.typealiases
    }
}

public class TypesCollection: DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        do {
            return try types(forKey: member)
        } catch {
            logger.error(error)
            return nil
        }
    }

    let all: [Type]
    let types: [String: [Type]]
    let validate: ((Type) throws -> Void)?

    init(types: [Type], collection: (Type) -> [String], validate: ((Type) throws -> Void)? = nil) {
        self.all = types
        var content = [String: [Type]]()
        self.all.forEach { type in
            collection(type).forEach { name in
                var list = content[name] ?? [Type]()
                list.append(type)
                content[name] = list
            }
        }
        self.types = content
        self.validate = validate
    }

    public func types(forKey key: String) throws -> [Type] {
        // In some configurations, the types are keyed by "ModuleName.TypeName"
        var longKey: String?

        if let validate = validate {
            guard let type = all.first(where: { $0.name == key }) else {
                throw TemplateContext.Error.unknownType(key)
            }

            try validate(type)

            if let module = type.module {
                longKey = [module, type.name].joined(separator: ".")
            }
        }

        // If we find the types directly, return them
        if let types = types[key] {
            return types
        }

        // if we find a types for the longKey, return them
        if let longKey = longKey, let types = types[longKey] {
            return types
        }

        return []
    }

    public subscript(_ key: String) -> [Type] {
        do {
            return try types(forKey: key)
        } catch {
            logger.error(error)
            return []
        }
    }
}
