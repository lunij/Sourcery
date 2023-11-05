import Foundation

struct ParsingResult {
    let parserResult: FileParserResult
    let types: Types
    let functions: [SourceryMethod]
    var inlineRanges: [(file: String, ranges: [String: NSRange], indentations: [String: String])]
}
