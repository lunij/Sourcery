import PathKit
import QuartzCore

public struct Configuration: Equatable {
    public let sources: Sources
    public let templates: Paths
    public let output: Output
    public let cacheBasePath: Path
    public let cacheDisabled: Bool
    public let forceParse: [String]
    public let parseDocumentation: Bool
    public let baseIndentation: Int
    public let arguments: [String: NSObject]

    public init(
        sources: Sources,
        templates: Paths,
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
