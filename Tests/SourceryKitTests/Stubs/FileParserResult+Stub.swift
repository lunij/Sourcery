import Foundation
import SourceryRuntime

extension FileParserResult {
    static func stub(
        path: String? = nil,
        module: String? = nil,
        types: [Type] = [],
        functions: [SourceryMethod] = [],
        typealiases: [Typealias] = [],
        inlineRanges: [String: NSRange] = [:],
        inlineIndentations: [String: String] = [:],
        modifiedDate: Date = .now,
        sourceryVersion: String = "fakeVersion"
    ) -> Self {
        .init(
            path: path,
            module: module,
            types: types,
            functions: functions,
            typealiases: typealiases,
            inlineRanges: inlineRanges,
            inlineIndentations: inlineIndentations,
            modifiedDate: modifiedDate,
            sourceryVersion: sourceryVersion
        )
    }
}
