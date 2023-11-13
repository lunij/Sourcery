import Foundation

public final class Typealias: Diffable, Typed, Equatable, Hashable {
    // New typealias name
    public let aliasName: String

    // Target name
    public let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    public var type: Type?

    /// module in which this typealias was declared
    public var module: String?

    // sourcery: skipEquality, skipDescription
    public var parent: Type? {
        didSet {
            parentName = parent?.name
        }
    }

    /// Type access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    public let accessLevel: String

    var parentName: String?

    public var name: String {
        if let parentName = parent?.name {
            return "\(module != nil ? "\(module!)." : "")\(parentName).\(aliasName)"
        } else {
            return "\(module != nil ? "\(module!)." : "")\(aliasName)"
        }
    }

    public init(aliasName: String = "", typeName: TypeName, accessLevel: AccessLevel = .internal, parent: Type? = nil, module: String? = nil) {
        self.aliasName = aliasName
        self.typeName = typeName
        self.accessLevel = accessLevel.rawValue
        self.parent = parent
        self.parentName = parent?.name
        self.module = module
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? Typealias else {
            results.append("Incorrect type <expected: Typealias, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "aliasName").trackDifference(actual: self.aliasName, expected: castObject.aliasName))
        results.append(contentsOf: DiffableResult(identifier: "typeName").trackDifference(actual: self.typeName, expected: castObject.typeName))
        results.append(contentsOf: DiffableResult(identifier: "module").trackDifference(actual: self.module, expected: castObject.module))
        results.append(contentsOf: DiffableResult(identifier: "accessLevel").trackDifference(actual: self.accessLevel, expected: castObject.accessLevel))
        results.append(contentsOf: DiffableResult(identifier: "parentName").trackDifference(actual: self.parentName, expected: castObject.parentName))
        return results
    }

    public var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "aliasName = \(String(describing: aliasName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "module = \(String(describing: module)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "parentName = \(String(describing: parentName)), "
        string += "name = \(String(describing: name))"
        return string
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(aliasName)
        hasher.combine(typeName)
        hasher.combine(module)
        hasher.combine(accessLevel)
        hasher.combine(parentName)
    }

    public static func == (lhs: Typealias, rhs: Typealias) -> Bool {
        if lhs.aliasName != rhs.aliasName { return false }
        if lhs.typeName != rhs.typeName { return false }
        if lhs.module != rhs.module { return false }
        if lhs.accessLevel != rhs.accessLevel { return false }
        if lhs.parentName != rhs.parentName { return false }
        return true
    }
}
