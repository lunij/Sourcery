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
    private let annotationParser: TemplateAnnotationParsing

    init(annotationParser: TemplateAnnotationParsing = TemplateAnnotationParser()) {
        self.annotationParser = annotationParser
    }

    func parse(
        _ content: String,
        path: Path? = nil,
        module: String? = nil,
        forceParse: [String] = [],
        parseDocumentation: Bool = false
    ) -> FileParserResult {
        let path = path?.string
        let modifiedDate = path.flatMap { (try? FileManager.default.attributesOfItem(atPath: $0)[.modificationDate]) as? Date }

        let inline = annotationParser.parseAnnotations("inline", contents: content, forceParse: forceParse)
        let content = inline.contents
        let inlineRanges = inline.annotatedRanges.mapValues { $0[0].range }
        let inlineIndentations = inline.annotatedRanges.mapValues { $0[0].indentation }

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
            modifiedDate: modifiedDate ?? Date()
        )
    }
}
