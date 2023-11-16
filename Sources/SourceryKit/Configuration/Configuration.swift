import PathKit

public struct Configuration: Equatable {
    public let sources: [SourceFile]
    public let templates: [Path]
    public let output: Path
    public let xcode: Xcode?
    public let cacheBasePath: Path
    public let cacheDisabled: Bool
    public let forceParse: [String]
    public let parseDocumentation: Bool
    public let arguments: [String: AnnotationValue]

    public init(
        sources: [SourceFile],
        templates: [Path],
        output: Path,
        xcode: Xcode?,
        cacheBasePath: Path,
        cacheDisabled: Bool,
        forceParse: [String],
        parseDocumentation: Bool,
        arguments: [String: AnnotationValue]
    ) {
        self.sources = sources
        self.templates = templates
        self.output = output
        self.xcode = xcode
        self.cacheBasePath = cacheBasePath
        self.cacheDisabled = cacheDisabled
        self.forceParse = forceParse
        self.parseDocumentation = parseDocumentation
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

public struct Xcode: Equatable {
    public let project: Path
    public let targets: [String]
    public let group: String?
}
