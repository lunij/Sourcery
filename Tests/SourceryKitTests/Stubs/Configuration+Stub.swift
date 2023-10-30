import Foundation
import SourceryKit

extension Configuration {
    static func stub(
        sources: [SourceFile] = [],
        templates: [Path] = [],
        output: Path = "",
        xcode: Xcode? = nil,
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
            xcode: xcode,
            cacheBasePath: cacheBasePath,
            cacheDisabled: cacheDisabled,
            forceParse: forceParse,
            parseDocumentation: parseDocumentation,
            baseIndentation: baseIndentation,
            arguments: arguments
        )
    }
}
