import Foundation

struct ParsingResult {
    let parserResult: FileParserResult
    let types: Types
    let functions: [Function]
    var inlineAnnotations: [(file: String, annotations: [BlockAnnotation])]
}
