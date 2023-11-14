import Foundation

/// Descibes common type properties
public protocol Typed {
    var type: Type? { get }
    var typeName: TypeName { get }
}

extension Typed {
    /// Whether type is optional. Shorthand for `typeName.isOptional`
    public var isOptional: Bool {
        typeName.isOptional
    }

    /// Whether type is implicitly unwrapped optional. Shorthand for `typeName.isImplicitlyUnwrappedOptional`
    public var isImplicitlyUnwrappedOptional: Bool {
        typeName.isImplicitlyUnwrappedOptional
    }

    /// Type name without attributes and optional type information. Shorthand for `typeName.unwrappedTypeName`
    public var unwrappedTypeName: String {
        typeName.unwrappedTypeName
    }

    /// Actual type name if declaration uses typealias, otherwise just a `typeName`. Shorthand for `typeName.actualTypeName`
    public var actualTypeName: TypeName? {
        typeName.actualTypeName ?? typeName
    }

    /// Whether type is a tuple. Shorthand for `typeName.isTuple`
    public var isTuple: Bool {
        typeName.isTuple
    }

    /// Whether type is a closure. Shorthand for `typeName.isClosure`
    public var isClosure: Bool {
        typeName.isClosure
    }

    /// Whether type is an array. Shorthand for `typeName.isArray`
    public var isArray: Bool {
        typeName.isArray
    }

    /// Whether type is a dictionary. Shorthand for `typeName.isDictionary`
    public var isDictionary: Bool {
        typeName.isDictionary
    }
}
