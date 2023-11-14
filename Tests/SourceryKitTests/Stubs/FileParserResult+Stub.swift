import Foundation
import SourceryKit

extension FileParserResult {
    static func stub(
        path: String? = nil,
        module: String? = nil,
        types: [Type] = [],
        functions: [Function] = [],
        typealiases: [Typealias] = [],
        inlineRanges: [String: NSRange] = [:],
        inlineIndentations: [String: String] = [:],
        modifiedDate: Date = .now
    ) -> Self {
        .init(
            path: path,
            module: module,
            types: types,
            functions: functions,
            typealiases: typealiases,
            inlineRanges: inlineRanges,
            inlineIndentations: inlineIndentations,
            modifiedDate: modifiedDate
        )
    }
}
