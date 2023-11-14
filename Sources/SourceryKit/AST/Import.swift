import Foundation

/// Defines an import
public struct Import: Hashable {
    /// Import kind, e.g. class, struct in `import class Module.ClassName`
    public var kind: String?

    /// Import path
    public var path: String

    /// Returns module name from a import, e.g. if you had `import struct Module.Submodule.Struct` it will return `Module.Submodule`
    public var moduleName: String {
        if kind != nil, let index = path.lastIndex(of: ".") {
            return String(path[..<index])
        }
        return path
    }

    public init(_ module: String) {
        self.path = module
        self.kind = nil
    }

    public init(kind: String?, path: String) {
        self.kind = kind
        self.path = path
    }
}

extension Import: CustomStringConvertible {
    public var description: String {
        if let kind {
            return "\(kind) \(path)"
        }
        return path
    }
}

extension Import: Diffable {
    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Import else {
            results.append("Incorrect type <expected: Import, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "kind").trackDifference(actual: kind, expected: castObject.kind))
        results.append(contentsOf: DiffableResult(identifier: "path").trackDifference(actual: path, expected: castObject.path))
        return results
    }
}
