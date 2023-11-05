import Foundation

/// Describes closure type
@objcMembers public final class ClosureType: NSObject, SourceryModel {

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
}
