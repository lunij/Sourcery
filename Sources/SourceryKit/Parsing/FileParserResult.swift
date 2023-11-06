import Foundation

@objcMembers public final class FileParserResult: NSObject, SourceryModel {
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
}
