import Foundation

/// Defines import type
public class Import: Diffable, Equatable, Hashable, CustomStringConvertible {
    /// Import kind, e.g. class, struct in `import class Module.ClassName`
    public var kind: String?

    /// Import path
    public var path: String

    public init(path: String, kind: String? = nil) {
        self.path = path
        self.kind = kind
    }

    /// Full import value e.g. `import struct Module.StructName`
    public var description: String {
        if let kind = kind {
            return "\(kind) \(path)"
        }

        return path
    }

    /// Returns module name from a import, e.g. if you had `import struct Module.Submodule.Struct` it will return `Module.Submodule`
    public var moduleName: String {
        if kind != nil {
            if let idx = path.lastIndex(of: ".") {
                return String(path[..<idx])
            } else {
                return path
            }
        } else {
            return path
        }
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Import else {
            results.append("Incorrect type <expected: Import, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "kind").trackDifference(actual: self.kind, expected: castObject.kind))
        results.append(contentsOf: DiffableResult(identifier: "path").trackDifference(actual: self.path, expected: castObject.path))
        return results
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(path)
    }

    public static func == (lhs: Import, rhs: Import) -> Bool {
        if lhs.kind != rhs.kind { return false }
        if lhs.path != rhs.path { return false }
        return true
    }
}
