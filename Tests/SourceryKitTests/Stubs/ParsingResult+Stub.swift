import Foundation
@testable import SourceryKit

extension ParsingResult {
    static func stub(
        parserResult: FileParserResult = .stub(),
        types: Types = .init(types: []),
        functions: [SourceryMethod] = [],
        inlineRanges: [(file: String, ranges: [String: NSRange], indentations: [String: String])] = []
    ) -> Self {
        .init(
            parserResult: parserResult,
            types: types,
            functions: functions,
            inlineRanges: inlineRanges
        )
    }
}
