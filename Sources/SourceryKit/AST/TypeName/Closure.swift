import Foundation

/// Describes closure type
public final class ClosureType: Diffable, Equatable, Hashable, CustomStringConvertible {

    /// Type name used in declaration with stripped whitespaces and new lines
    public let name: String

    /// List of closure parameters
    public let parameters: [ClosureParameter]

    /// Return value type name
    public let returnTypeName: TypeName

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
        return returnTypeName.isOptional
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

    /// async keyword
    public let asyncKeyword: String?

    /// Whether closure throws
    public let `throws`: Bool

    /// throws or rethrows keyword
    public let throwsOrRethrowsKeyword: String?

    public init(name: String, parameters: [ClosureParameter], returnTypeName: TypeName, returnType: Type? = nil, asyncKeyword: String? = nil, throwsOrRethrowsKeyword: String? = nil) {
        self.name = name
        self.parameters = parameters
        self.returnTypeName = returnTypeName
        self.returnType = returnType
        self.asyncKeyword = asyncKeyword
        self.isAsync = asyncKeyword != nil
        self.throwsOrRethrowsKeyword = throwsOrRethrowsKeyword
        self.`throws` = throwsOrRethrowsKeyword != nil
    }

    public var asSource: String {
        "\(parameters.asSource)\(asyncKeyword != nil ? " \(asyncKeyword!)" : "")\(throwsOrRethrowsKeyword != nil ? " \(throwsOrRethrowsKeyword!)" : "") -> \(returnTypeName.asSource)"
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? ClosureType else {
            results.append("Incorrect type <expected: ClosureType, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "parameters").trackDifference(actual: self.parameters, expected: castObject.parameters))
        results.append(contentsOf: DiffableResult(identifier: "returnTypeName").trackDifference(actual: self.returnTypeName, expected: castObject.returnTypeName))
        results.append(contentsOf: DiffableResult(identifier: "isAsync").trackDifference(actual: self.isAsync, expected: castObject.isAsync))
        results.append(contentsOf: DiffableResult(identifier: "asyncKeyword").trackDifference(actual: self.asyncKeyword, expected: castObject.asyncKeyword))
        results.append(contentsOf: DiffableResult(identifier: "`throws`").trackDifference(actual: self.`throws`, expected: castObject.`throws`))
        results.append(contentsOf: DiffableResult(identifier: "throwsOrRethrowsKeyword").trackDifference(actual: self.throwsOrRethrowsKeyword, expected: castObject.throwsOrRethrowsKeyword))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "name = \(String(describing: name)), "
        string += "parameters = \(String(describing: parameters)), "
        string += "returnTypeName = \(String(describing: returnTypeName)), "
        string += "actualReturnTypeName = \(String(describing: actualReturnTypeName)), "
        string += "isAsync = \(String(describing: isAsync)), "
        string += "asyncKeyword = \(String(describing: asyncKeyword)), "
        string += "`throws` = \(String(describing: `throws`)), "
        string += "throwsOrRethrowsKeyword = \(String(describing: throwsOrRethrowsKeyword)), "
        string += "asSource = \(String(describing: asSource))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parameters)
        hasher.combine(returnTypeName)
        hasher.combine(isAsync)
        hasher.combine(asyncKeyword)
        hasher.combine(`throws`)
        hasher.combine(throwsOrRethrowsKeyword)
    }

    public static func == (lhs: ClosureType, rhs: ClosureType) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.parameters != rhs.parameters { return false }
        if lhs.returnTypeName != rhs.returnTypeName { return false }
        if lhs.isAsync != rhs.isAsync { return false }
        if lhs.asyncKeyword != rhs.asyncKeyword { return false }
        if lhs.`throws` != rhs.`throws` { return false }
        if lhs.throwsOrRethrowsKeyword != rhs.throwsOrRethrowsKeyword { return false }
        return true
    }
}
