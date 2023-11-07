import Foundation

@objcMembers public final class Typealias: NSObject, Typed, SourceryModel {
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

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "aliasName = \(String(describing: aliasName)), "
        string += "typeName = \(String(describing: typeName)), "
        string += "module = \(String(describing: module)), "
        string += "accessLevel = \(String(describing: accessLevel)), "
        string += "parentName = \(String(describing: parentName)), "
        string += "name = \(String(describing: name))"
        return string
    }
}
