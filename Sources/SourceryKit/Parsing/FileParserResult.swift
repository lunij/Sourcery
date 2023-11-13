import Foundation

public final class FileParserResult: Diffable, Equatable, Hashable, CustomStringConvertible {
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

        defer {
            self.types = types
        }
    }

    public func diffAgainst(_ object: Any?) -> DiffableResult {
        let results = DiffableResult()
        guard let castObject = object as? FileParserResult else {
            results.append("Incorrect type <expected: FileParserResult, received: \(Swift.type(of: object))>")
            return results
        }
        results.append(contentsOf: DiffableResult(identifier: "path").trackDifference(actual: self.path, expected: castObject.path))
        results.append(contentsOf: DiffableResult(identifier: "module").trackDifference(actual: self.module, expected: castObject.module))
        results.append(contentsOf: DiffableResult(identifier: "types").trackDifference(actual: self.types, expected: castObject.types))
        results.append(contentsOf: DiffableResult(identifier: "functions").trackDifference(actual: self.functions, expected: castObject.functions))
        results.append(contentsOf: DiffableResult(identifier: "typealiases").trackDifference(actual: self.typealiases, expected: castObject.typealiases))
        results.append(contentsOf: DiffableResult(identifier: "inlineRanges").trackDifference(actual: self.inlineRanges, expected: castObject.inlineRanges))
        results.append(contentsOf: DiffableResult(identifier: "inlineIndentations").trackDifference(actual: self.inlineIndentations, expected: castObject.inlineIndentations))
        results.append(contentsOf: DiffableResult(identifier: "modifiedDate").trackDifference(actual: self.modifiedDate, expected: castObject.modifiedDate))
        return results
    }

    public var description: String {
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(module)
        hasher.combine(types)
        hasher.combine(functions)
        hasher.combine(typealiases)
        hasher.combine(inlineRanges)
        hasher.combine(inlineIndentations)
        hasher.combine(modifiedDate)
    }

    public static func == (lhs: FileParserResult, rhs: FileParserResult) -> Bool {
        lhs.path == rhs.path
            && lhs.module == rhs.module
            && lhs.types == rhs.types
            && lhs.functions == rhs.functions
            && lhs.typealiases == rhs.typealiases
            && lhs.inlineRanges == rhs.inlineRanges
            && lhs.inlineIndentations == rhs.inlineIndentations
            && lhs.modifiedDate == rhs.modifiedDate
    }
}
