import Foundation
import Stencil

/// Describes name of the type used in typed declaration (variable, method parameter or return value etc.)
public final class TypeName: Diffable, LosslessStringConvertible, Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, DynamicMemberLookup {
    public subscript(dynamicMember member: String) -> Any? {
        switch member {
        case "actualTypeName": actualTypeName
        case "array": array
        case "asSource": asSource
        case "attributes": attributes
        case "closure": closure
        case "debugDescription": debugDescription
        case "description": description
        case "dictionary": dictionary
        case "generic": generic
        case "isArray": isArray
        case "isClosure": isClosure
        case "isDictionary": isDictionary
        case "isGeneric": isGeneric
        case "isImplicitlyUnwrappedOptional": isImplicitlyUnwrappedOptional
        case "isOptional": isOptional
        case "isProtocolComposition": isProtocolComposition
        case "isTuple": isTuple
        case "isVoid": isVoid
        case "modifiers": modifiers
        case "name": name
        case "tuple": tuple
        case "unwrappedTypeName": unwrappedTypeName
        default:
            preconditionFailure("Member named '\(member)' does not exist.")
        }
    }

    public init(name: String,
                actualTypeName: TypeName? = nil,
                unwrappedTypeName: String? = nil,
                attributes: AttributeList = [:],
                isOptional: Bool = false,
                isImplicitlyUnwrappedOptional: Bool = false,
                tuple: TupleType? = nil,
                array: ArrayType? = nil,
                dictionary: DictionaryType? = nil,
                closure: ClosureType? = nil,
                generic: GenericType? = nil,
                isProtocolComposition: Bool = false) {

        let optionalSuffix: String
        // TODO: TBR
        if !name.hasPrefix("Optional<") && !name.contains(" where ") {
            if isOptional {
                optionalSuffix = "?"
            } else if isImplicitlyUnwrappedOptional {
                optionalSuffix = "!"
            } else {
                optionalSuffix = ""
            }
        } else {
            optionalSuffix = ""
        }

        self.name = name + optionalSuffix
        self.actualTypeName = actualTypeName
        self.unwrappedTypeName = unwrappedTypeName ?? name
        self.tuple = tuple
        self.array = array
        self.dictionary = dictionary
        self.closure = closure
        self.generic = generic
        self.isOptional = isOptional || isImplicitlyUnwrappedOptional
        self.isImplicitlyUnwrappedOptional = isImplicitlyUnwrappedOptional
        self.isProtocolComposition = isProtocolComposition

        self.attributes = attributes
        self.modifiers = []
    }

    /// Type name used in declaration
    public var name: String

    /// The generics of this TypeName
    public var generic: GenericType?

    /// Whether this TypeName is generic
    public var isGeneric: Bool {
        actualTypeName?.generic != nil || generic != nil
    }

    /// Whether this TypeName is protocol composition
    public var isProtocolComposition: Bool

    // sourcery: skipEquality
    /// Actual type name if given type name is a typealias
    public var actualTypeName: TypeName?

    /// Type name attributes, i.e. `@escaping`
    public var attributes: AttributeList

    /// Modifiers, i.e. `escaping`
    public var modifiers: [SourceryModifier]

    // sourcery: skipEquality
    /// Whether type is optional
    public let isOptional: Bool

    // sourcery: skipEquality
    /// Whether type is implicitly unwrapped optional
    public let isImplicitlyUnwrappedOptional: Bool

    // sourcery: skipEquality
    /// Type name without attributes and optional type information
    public var unwrappedTypeName: String

    // sourcery: skipEquality
    /// Whether type is void (`Void` or `()`)
    public var isVoid: Bool {
        return name == "Void" || name == "()" || unwrappedTypeName == "Void"
    }

    /// Whether type is a tuple
    public var isTuple: Bool {
        actualTypeName?.tuple != nil || tuple != nil
    }

    /// Tuple type data
    public var tuple: TupleType?

    /// Whether type is an array
    public var isArray: Bool {
        actualTypeName?.array != nil || array != nil
    }

    /// Array type data
    public var array: ArrayType?

    /// Whether type is a dictionary
    public var isDictionary: Bool {
        actualTypeName?.dictionary != nil || dictionary != nil
    }

    /// Dictionary type data
    public var dictionary: DictionaryType?

    /// Whether type is a closure
    public var isClosure: Bool {
        actualTypeName?.closure != nil || closure != nil
    }

    /// Closure type data
    public var closure: ClosureType?

    /// Prints typename as it would appear on definition
    public var asSource: String {
        // TODO: TBR special treatment
        let specialTreatment = isOptional && name.hasPrefix("Optional<")

        var description = (
            attributes.flatMap({ $0.value }).map(\.description).sorted() +
            modifiers.map({ $0.asSource }) +
            [specialTreatment ? name : unwrappedTypeName]
        ).joined(separator: " ")

        if let _ = self.dictionary { // array and dictionary cases are covered by the unwrapped type name
//            description.append(dictionary.asSource)
        } else if let _ = self.array {
//            description.append(array.asSource)
        } else if let _ = self.generic {
//            let arguments = generic.typeParameters
//              .map({ $0.typeName.asSource })
//              .joined(separator: ", ")
//            description.append("<\(arguments)>")
        }
        if !specialTreatment {
            if isImplicitlyUnwrappedOptional {
                description.append("!")
            } else if isOptional {
                description.append("?")
            }
        }

        return description
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? TypeName else {
            results.append("Incorrect type <expected: TypeName, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "generic").trackDifference(actual: self.generic, expected: castObject.generic))
        results.append(contentsOf: DiffableResult(identifier: "isProtocolComposition").trackDifference(actual: self.isProtocolComposition, expected: castObject.isProtocolComposition))
        results.append(contentsOf: DiffableResult(identifier: "attributes").trackDifference(actual: self.attributes, expected: castObject.attributes))
        results.append(contentsOf: DiffableResult(identifier: "modifiers").trackDifference(actual: self.modifiers, expected: castObject.modifiers))
        results.append(contentsOf: DiffableResult(identifier: "tuple").trackDifference(actual: self.tuple, expected: castObject.tuple))
        results.append(contentsOf: DiffableResult(identifier: "array").trackDifference(actual: self.array, expected: castObject.array))
        results.append(contentsOf: DiffableResult(identifier: "dictionary").trackDifference(actual: self.dictionary, expected: castObject.dictionary))
        results.append(contentsOf: DiffableResult(identifier: "closure").trackDifference(actual: self.closure, expected: castObject.closure))
        return results
    }

    public var description: String {
       (
          attributes.flatMap({ $0.value }).map(\.description).sorted() +
          modifiers.map({ $0.asSource }) +
          [name]
        ).joined(separator: " ")
    }

    // sourcery: skipEquality, skipDescription
    public var debugDescription: String {
        return name
    }

    public convenience init(_ description: String) {
        self.init(name: description, actualTypeName: nil)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(generic)
        hasher.combine(isProtocolComposition)
        hasher.combine(attributes)
        hasher.combine(modifiers)
        hasher.combine(tuple)
        hasher.combine(array)
        hasher.combine(dictionary)
        hasher.combine(closure)
    }

    public static func == (lhs: TypeName, rhs: TypeName) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.generic != rhs.generic { return false }
        if lhs.isProtocolComposition != rhs.isProtocolComposition { return false }
        if lhs.attributes != rhs.attributes { return false }
        if lhs.modifiers != rhs.modifiers { return false }
        if lhs.tuple != rhs.tuple { return false }
        if lhs.array != rhs.array { return false }
        if lhs.dictionary != rhs.dictionary { return false }
        if lhs.closure != rhs.closure { return false }
        return true
    }
}

extension TypeName {
    public static func unknown(description: String?, attributes: AttributeList = [:]) -> TypeName {
        if let description = description {
            logger.astWarning("Unknown type, please add type attribution to \(description)")
        } else {
            logger.astWarning("Unknown type, please add type attribution")
        }
        return TypeName(name: "UnknownTypeSoAddTypeAttributionToVariable", attributes: attributes)
    }
}
