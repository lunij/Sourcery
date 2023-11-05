import Foundation
import SourceryKit

extension Configuration {
    static func stub(
        sources: [SourceFile] = [],
        templates: [Path] = [],
        output: Path = "fakeOutput",
        xcode: Xcode? = nil,
        cacheBasePath: Path = "fakeCacheBashePath",
        cacheDisabled: Bool = true,
        forceParse: [String] = [],
        parseDocumentation: Bool = false,
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
            arguments: arguments
        )
    }
}
