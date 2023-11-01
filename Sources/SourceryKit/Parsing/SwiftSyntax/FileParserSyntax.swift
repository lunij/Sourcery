import Foundation
import SwiftSyntax
import SwiftParser
import PathKit
import SourceryRuntime

public final class FileParserSyntax: SyntaxVisitor {

    public let path: String?
    public let modifiedDate: Date?

    private let module: String?
    private let initialContents: String
 
    fileprivate var inlineRanges: [String: NSRange]!
    fileprivate var inlineIndentations: [String: String]!
    fileprivate var forceParse: [String] = []
    fileprivate var parseDocumentation: Bool = false

    private let annotationParser: TemplateAnnotationParsing

    /// Parses given contents.
    /// - Throws: parsing errors.
    public init(
        contents: String,
        forceParse: [String] = [],
        parseDocumentation: Bool = false,
        path: Path? = nil,
        module: String? = nil
    ) throws {
        self.path = path?.string
        self.modifiedDate = path.flatMap({ (try? FileManager.default.attributesOfItem(atPath: $0.string)[.modificationDate]) as? Date })
        self.module = module
        self.initialContents = contents
        self.forceParse = forceParse
        self.parseDocumentation = parseDocumentation
        annotationParser = TemplateAnnotationParser()
        super.init(viewMode: .fixedUp)
    }

    /// Parses given file context.
    ///
    /// - Returns: All types we could find.
    public func parse() throws -> FileParserResult {
        // Inline handling
        let inline = annotationParser.parseAnnotations("inline", contents: initialContents, forceParse: self.forceParse)
        let content = inline.contents
        inlineRanges = inline.annotatedRanges.mapValues { $0[0].range }
        inlineIndentations = inline.annotatedRanges.mapValues { $0[0].indentation }

        // Syntax walking
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
