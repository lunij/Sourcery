import Foundation

/// Describes Swift attribute
public class Attribute: Diffable, Equatable, Hashable, CustomStringConvertible {

    /// Attribute name
    public let name: String

    /// Attribute arguments
    public let arguments: [String: NSObject]

    let _description: String

    // sourcery: skipEquality, skipDescription, skipCoding
    public var __parserData: Any?

    public init(name: String, arguments: [String: NSObject] = [:], description: String? = nil) {
        self.name = name
        self.arguments = arguments
        self._description = description ?? "@\(name)"
    }

    /// TODO: unify `asSource` / `description`?
    public var asSource: String {
        description
    }

    /// Attribute description that can be used in a template.
    public var description: String {
        return _description
    }

    public enum Identifier: String {
        case convenience
        case required
        case available
        case discardableResult
        case GKInspectable = "gkinspectable"
        case objc
        case objcMembers
        case nonobjc
        case NSApplicationMain
        case NSCopying
        case NSManaged
        case UIApplicationMain
        case IBOutlet = "iboutlet"
        case IBInspectable = "ibinspectable"
        case IBDesignable = "ibdesignable"
        case autoclosure
        case convention
        case mutating
        case escaping
        case final
        case open
        case lazy
        case `public` = "public"
        case `internal` = "internal"
        case `private` = "private"
        case `fileprivate` = "fileprivate"
        case publicSetter = "setter_access.public"
        case internalSetter = "setter_access.internal"
        case privateSetter = "setter_access.private"
        case fileprivateSetter = "setter_access.fileprivate"
        case optional

        public init?(identifier: String) {
            let identifier = identifier.trimmingPrefix("source.decl.attribute.")
            if identifier == "objc.name" {
                self.init(rawValue: "objc")
            } else {
                self.init(rawValue: identifier)
            }
        }

        public static func from(string: String) -> Identifier? {
            switch string {
            case "GKInspectable":
                return Identifier.GKInspectable
            case "objc":
                return .objc
            case "IBOutlet":
                return .IBOutlet
            case "IBInspectable":
                return .IBInspectable
            case "IBDesignable":
                return .IBDesignable
            default:
                return Identifier(rawValue: string)
            }
        }

        public var name: String {
            switch self {
            case .GKInspectable:
                return "GKInspectable"
            case .objc:
                return "objc"
            case .IBOutlet:
                return "IBOutlet"
            case .IBInspectable:
                return "IBInspectable"
            case .IBDesignable:
                return "IBDesignable"
            case .fileprivateSetter:
                return "fileprivate"
            case .privateSetter:
                return "private"
            case .internalSetter:
                return "internal"
            case .publicSetter:
                return "public"
            default:
                return rawValue
            }
        }

        public var description: String {
            return hasAtPrefix ? "@\(name)" : name
        }

        public var hasAtPrefix: Bool {
            switch self {
            case .available,
                 .discardableResult,
                 .GKInspectable,
                 .objc,
                 .objcMembers,
                 .nonobjc,
                 .NSApplicationMain,
                 .NSCopying,
                 .NSManaged,
                 .UIApplicationMain,
                 .IBOutlet,
                 .IBInspectable,
                 .IBDesignable,
                 .autoclosure,
                 .convention,
                 .escaping:
                return true
            default:
                return false
            }
        }
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Attribute else {
            results.append("Incorrect type <expected: Attribute, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "name").trackDifference(actual: self.name, expected: castObject.name))
        results.append(contentsOf: DiffableResult(identifier: "arguments").trackDifference(actual: self.arguments, expected: castObject.arguments))
        results.append(contentsOf: DiffableResult(identifier: "_description").trackDifference(actual: self._description, expected: castObject._description))
        return results
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(arguments)
        hasher.combine(_description)
    }

    public static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        if lhs.name != rhs.name { return false }
        if lhs.arguments != rhs.arguments { return false }
        if lhs._description != rhs._description { return false }
        return true
    }
}
