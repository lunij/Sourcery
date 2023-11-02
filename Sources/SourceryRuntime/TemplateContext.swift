import Foundation

/// :nodoc:
// sourcery: skipCoding
@objcMembers public final class TemplateContext: NSObject, SourceryModel, NSCoding {
    public let parserResult: FileParserResult?
    public let functions: [SourceryMethod]
    public let types: Types
    public let argument: [String: NSObject]

    // sourcery: skipDescription
    public var type: [String: Type] {
        return types.typesByName
    }

    public init(parserResult: FileParserResult?, types: Types, functions: [SourceryMethod], arguments: [String: NSObject]) {
        self.parserResult = parserResult
        self.types = types
        self.functions = functions
        self.argument = arguments
    }

    /// :nodoc:
    required public init?(coder aDecoder: NSCoder) {
        guard let parserResult: FileParserResult = aDecoder.decode(forKey: "parserResult") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found. FileParserResults are required for template context that needs persisting.", arguments: getVaList(["parserResult"])); fatalError() }
        guard let argument: [String: NSObject] = aDecoder.decode(forKey: "argument") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["argument"])); fatalError() }

        // if we want to support multiple cycles of encode / decode we need deep copy because composer changes reference types
        let fileParserResultCopy: FileParserResult? = nil
//      fileParserResultCopy = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(NSKeyedArchiver.archivedData(withRootObject: parserResult)) as? FileParserResult

        let composed = Composer.uniqueTypesAndFunctions(parserResult)
        self.types = .init(types: composed.types, typealiases: composed.typealiases)
        self.functions = composed.functions

        self.parserResult = fileParserResultCopy
        self.argument = argument
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.parserResult, forKey: "parserResult")
        aCoder.encode(self.argument, forKey: "argument")
    }

    public var stencilContext: [String: Any] {
        return [
            "types": types,
            "functions": functions,
            "type": types.typesByName,
            "argument": argument
        ]
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

extension ProcessInfo {
    public func unarchiveContext() throws -> TemplateContext? {
        let data = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
        return try NSKeyedUnarchiver.unarchivedRootObject(ofClass: TemplateContext.self, from: data)
    }
}

/// Collection of scanned types for accessing in templates
@objcMembers public final class Types: NSObject, SourceryModel {

    /// :nodoc:
    public let types: [Type]

    /// All known typealiases
    public let typealiases: [Typealias]

    /// :nodoc:
    public init(types: [Type], typealiases: [Typealias] = []) {
        self.types = types
        self.typealiases = typealiases
    }

// sourcery:inline:Types.AutoCoding
public required init?(coder aDecoder: NSCoder) {
    guard let types: [Type] = aDecoder.decode(forKey: "types") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["types"])); fatalError() }; self.types = types
    guard let typealiases: [Typealias] = aDecoder.decode(forKey: "typealiases") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typealiases"])); fatalError() }; self.typealiases = typealiases
}

public func encode(with aCoder: NSCoder) {
    aCoder.encode(types, forKey: "types")
    aCoder.encode(typealiases, forKey: "typealiases")
}
// sourcery:end

    // sourcery: skipDescription, skipEquality, skipCoding
    /// :nodoc:
    public lazy internal(set) var typesByName: [String: Type] = {
        var typesByName = [String: Type]()
        self.types.forEach { typesByName[$0.globalName] = $0 }
        return typesByName
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// :nodoc:
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
}

/// :nodoc:
@objcMembers public class TypesCollection: NSObject {
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

    /// :nodoc:
    public override func value(forKey key: String) -> Any? {
        do {
            return try types(forKey: key)
        } catch {
            logger.error(error)
            return nil
        }
    }

    /// :nodoc:
    public subscript(_ key: String) -> [Type] {
        do {
            return try types(forKey: key)
        } catch {
            logger.error(error)
            return []
        }
    }

    public override func responds(to aSelector: Selector!) -> Bool {
        return true
    }
}
