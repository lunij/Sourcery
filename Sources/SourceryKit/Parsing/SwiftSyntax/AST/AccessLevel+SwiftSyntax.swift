import SwiftSyntax

extension AccessLevel {
    init?(_ modifier: Modifier) {
        switch modifier.name {
        case "public":
            self = .public
        case "private":
            self = .private
        case "fileprivate":
            self = .fileprivate
        case "internal":
            self = .internal
        case "open":
            self = .open
        default:
            return nil
        }
    }

    static func `default`(for parent: Type?) -> AccessLevel {
        var defaultAccess = AccessLevel.internal
        if let type = parent, type.isExtension || type is SourceryProtocol {
            defaultAccess = AccessLevel(rawValue: type.accessLevel) ?? defaultAccess
        }

        return defaultAccess
    }
}
