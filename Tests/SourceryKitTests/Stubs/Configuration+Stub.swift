import Foundation
import SourceryKit

extension Configuration {
    static func stub(
        sources: Paths = .init(include: []),
        templates: Paths = .init(include: []),
        output: Output = .init(""),
        cacheBasePath: Path = "",
        cacheDisabled: Bool = true,
        forceParse: [String] = [],
        parseDocumentation: Bool = false,
        baseIndentation: Int = 0,
        arguments: [String: NSObject] = [:]
    ) -> Self {
        .init(
            sources: sources,
            templates: templates,
            output: output,
            cacheBasePath: cacheBasePath,
            cacheDisabled: cacheDisabled,
            forceParse: forceParse,
            parseDocumentation: parseDocumentation,
            baseIndentation: baseIndentation,
            arguments: arguments
        )
    }
}
