import Foundation

/// Defines import type
@objcMembers public class Import: NSObject, SourceryModelWithoutDescription {
    /// Import kind, e.g. class, struct in `import class Module.ClassName`
    public var kind: String?

    /// Import path
    public var path: String

    /// :nodoc:
    public init(path: String, kind: String? = nil) {
        self.path = path
        self.kind = kind
    }

    /// Full import value e.g. `import struct Module.StructName`
    override public var description: String {
        if let kind {
            return "\(kind) \(path)"
        }

        return path
    }

    /// Returns module name from a import, e.g. if you had `import struct Module.Submodule.Struct` it will return `Module.Submodule`
    public var moduleName: String {
        if kind != nil {
            if let idx = path.lastIndex(of: ".") {
                String(path[..<idx])
            } else {
                path
            }
        } else {
            path
        }
    }

    // sourcery:inline:Import.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        kind = aDecoder.decode(forKey: "kind")
        guard let path: String = aDecoder.decode(forKey: "path") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["path"])); fatalError() }; self.path = path
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(kind, forKey: "kind")
        aCoder.encode(path, forKey: "path")
    }

    // sourcery:end
}
