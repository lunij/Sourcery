import Foundation
import SourceryKit

extension Configuration {
    static func stub(
        sources: Sources,
        templates: Paths,
        output: Output,
        cacheBasePath: Path = "",
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
            forceParse: forceParse,
            parseDocumentation: parseDocumentation,
            baseIndentation: baseIndentation,
            arguments: arguments
        )
    }
}
