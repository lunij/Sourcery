import Foundation

@objcMembers public final class FileParserResult: NSObject {
    public let path: String?
    public let module: String?
    public var types = [Type]() {
        didSet {
            types.forEach { type in
                guard type.module == nil, type.kind != "extensions" else { return }
                type.module = module
            }
        }
    }

    public var functions: [SourceryMethod]
    public var typealiases: [Typealias]
    public var inlineRanges: [String: NSRange]
    public var inlineIndentations: [String: String]

    public var modifiedDate: Date

    var isEmpty: Bool {
        types.isEmpty && functions.isEmpty && typealiases.isEmpty && inlineRanges.isEmpty && inlineIndentations.isEmpty
    }

    public init(
        path: String?,
        module: String?,
        types: [Type],
        functions: [SourceryMethod],
        typealiases: [Typealias] = [],
        inlineRanges: [String: NSRange] = [:],
        inlineIndentations: [String: String] = [:],
        modifiedDate: Date = Date()
    ) {
        self.path = path
        self.module = module
        self.types = types
        self.functions = functions
        self.typealiases = typealiases
        self.inlineRanges = inlineRanges
        self.inlineIndentations = inlineIndentations
        self.modifiedDate = modifiedDate

        super.init()

        defer {
            self.types = types
        }
    }

    public override var description: String {
        var string = "\(Swift.type(of: self)): "
        string += "path = \(String(describing: path)), "
        string += "module = \(String(describing: module)), "
        string += "types = \(String(describing: types)), "
        string += "functions = \(String(describing: functions)), "
        string += "typealiases = \(String(describing: typealiases)), "
        string += "inlineRanges = \(String(describing: inlineRanges)), "
        string += "inlineIndentations = \(String(describing: inlineIndentations)), "
        string += "modifiedDate = \(String(describing: modifiedDate)), "
        string += "isEmpty = \(String(describing: isEmpty))"
        return string
    }
}
