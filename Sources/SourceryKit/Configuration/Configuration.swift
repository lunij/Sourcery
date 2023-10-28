import PathKit
import QuartzCore

public struct Configuration: Equatable {
    public let sources: [SourceFile]
    public let templates: [Path]
    public let output: Output
    public let cacheBasePath: Path
    public let cacheDisabled: Bool
    public let forceParse: [String]
    public let parseDocumentation: Bool
    public let baseIndentation: Int
    public let arguments: [String: NSObject]

    public init(
        sources: [SourceFile],
        templates: [Path],
        output: Output,
        cacheBasePath: Path,
        cacheDisabled: Bool,
        forceParse: [String],
        parseDocumentation: Bool,
        baseIndentation: Int,
        arguments: [String: NSObject]
    ) {
        self.sources = sources
        self.templates = templates
        self.output = output
        self.cacheBasePath = cacheBasePath
        self.cacheDisabled = cacheDisabled
        self.forceParse = forceParse
        self.parseDocumentation = parseDocumentation
        self.baseIndentation = baseIndentation
        self.arguments = arguments
    }
}

public struct SourceFile: Equatable, ExpressibleByStringLiteral {
    let path: Path
    let module: String?

    public init(path: Path, module: String? = nil) {
        self.path = path
        self.module = module
    }

    public init(stringLiteral value: String) {
        self.init(path: .init(value))
    }
}
