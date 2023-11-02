import Foundation
import PathKit
import SourceryRuntime
import SwiftParser
import SwiftSyntax

protocol SwiftSyntaxParsing {
    func parse(
        _ content: String,
        path: Path?,
        module: String?,
        forceParse: [String],
        parseDocumentation: Bool
    ) -> FileParserResult
}

final class SwiftSyntaxParser: SwiftSyntaxParsing {
    private let blockAnnotationParser: BlockAnnotationParsing

    init(blockAnnotationParser: BlockAnnotationParsing = BlockAnnotationParser()) {
        self.blockAnnotationParser = blockAnnotationParser
    }

    func parse(
        _ content: String,
        path: Path? = nil,
        module: String? = nil,
        forceParse: [String] = [],
        parseDocumentation: Bool = false
    ) -> FileParserResult {
        let modificationDate = path?.modificationDate
        let path = path?.string

        let inline = blockAnnotationParser.parseAnnotations("inline", content: content, forceParse: forceParse)
        let content = inline.content
        let inlineRanges = inline.annotations.mapValues { $0[0].range }
        let inlineIndentations = inline.annotations.mapValues { $0[0].indentation }

        let tree = Parser.parse(source: content)
        let fileName = path ?? "in-memory"
        let sourceLocationConverter = SourceLocationConverter(file: fileName, tree: tree)
        let collector = SyntaxTreeCollector(
            file: fileName,
            module: module,
            getAnnotationUseCase: GetAnnotationUseCase(
                content: content,
                sourceLocationConverter: sourceLocationConverter,
                parseDocumentation: parseDocumentation
            ),
            sourceLocationConverter: sourceLocationConverter)
        collector.walk(tree)

        collector.types.forEach {
            $0.imports = collector.imports
            $0.path = path
        }

        return FileParserResult(
            path: path,
            module: module,
            types: collector.types,
            functions: collector.methods,
            typealiases: collector.typealiases,
            inlineRanges: inlineRanges,
            inlineIndentations: inlineIndentations,
            modifiedDate: modificationDate ?? Date()
        )
    }
}
