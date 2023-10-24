import Foundation

// sourcery: skipJSExport
/// :nodoc:
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
            "\(module != nil ? "\(module!)." : "")\(parentName).\(aliasName)"
        } else {
            "\(module != nil ? "\(module!)." : "")\(aliasName)"
        }
    }

    public init(aliasName: String = "", typeName: TypeName, accessLevel: AccessLevel = .internal, parent: Type? = nil, module: String? = nil) {
        self.aliasName = aliasName
        self.typeName = typeName
        self.accessLevel = accessLevel.rawValue
        self.parent = parent
        parentName = parent?.name
        self.module = module
    }

    // sourcery:inline:Typealias.AutoCoding

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        guard let aliasName: String = aDecoder.decode(forKey: "aliasName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["aliasName"])); fatalError() }; self.aliasName = aliasName
        guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
        type = aDecoder.decode(forKey: "type")
        module = aDecoder.decode(forKey: "module")
        parent = aDecoder.decode(forKey: "parent")
        guard let accessLevel: String = aDecoder.decode(forKey: "accessLevel") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["accessLevel"])); fatalError() }; self.accessLevel = accessLevel
        parentName = aDecoder.decode(forKey: "parentName")
    }

    /// :nodoc:
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(aliasName, forKey: "aliasName")
        aCoder.encode(typeName, forKey: "typeName")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(module, forKey: "module")
        aCoder.encode(parent, forKey: "parent")
        aCoder.encode(accessLevel, forKey: "accessLevel")
        aCoder.encode(parentName, forKey: "parentName")
    }
    // sourcery:end
}
