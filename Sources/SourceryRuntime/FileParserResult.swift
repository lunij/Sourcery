import Foundation

/// :nodoc:
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
    public var functions = [SourceryMethod]()
    public var typealiases = [Typealias]()
    public var inlineRanges = [String: Range<Substring.Index>]()
    public var inlineIndentations = [String: String]()

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
        inlineRanges: [String: Range<Substring.Index>] = [:],
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

// sourcery:inline:FileParserResult.AutoCoding

/// :nodoc:
public required init?(coder aDecoder: NSCoder) {
    path = aDecoder.decode(forKey: "path")
    module = aDecoder.decode(forKey: "module")
    guard let types: [Type] = aDecoder.decode(forKey: "types") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["types"])); fatalError() }; self.types = types
    guard let functions: [SourceryMethod] = aDecoder.decode(forKey: "functions") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["functions"])); fatalError() }; self.functions = functions
    guard let typealiases: [Typealias] = aDecoder.decode(forKey: "typealiases") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typealiases"])); fatalError() }; self.typealiases = typealiases
    guard let inlineRanges: [String: Range<Substring.Index>] = aDecoder.decode(forKey: "inlineRanges") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["inlineRanges"])); fatalError() }; self.inlineRanges = inlineRanges
    guard let inlineIndentations: [String: String] = aDecoder.decode(forKey: "inlineIndentations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["inlineIndentations"])); fatalError() }; self.inlineIndentations = inlineIndentations
    guard let modifiedDate: Date = aDecoder.decode(forKey: "modifiedDate") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["modifiedDate"])); fatalError() }; self.modifiedDate = modifiedDate
}

/// :nodoc:
public func encode(with aCoder: NSCoder) {
    aCoder.encode(path, forKey: "path")
    aCoder.encode(module, forKey: "module")
    aCoder.encode(types, forKey: "types")
    aCoder.encode(functions, forKey: "functions")
    aCoder.encode(typealiases, forKey: "typealiases")
    aCoder.encode(inlineRanges, forKey: "inlineRanges")
    aCoder.encode(inlineIndentations, forKey: "inlineIndentations")
    aCoder.encode(modifiedDate, forKey: "modifiedDate")
}
// sourcery:end
}
