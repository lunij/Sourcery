import Foundation
import PathKit
import SourceryRuntime

public class SwiftGenerator {
    typealias SourceChange = (path: String, rangeInFile: NSRange, newRangeInFile: NSRange)
    typealias GenerationResult = (String, [SourceChange])

    // content annotated with file annotations per file path to write it to
    private var fileAnnotatedContent: [Path: [String]] = [:]

    private let clock: TimeMeasuring
    private let blockAnnotationParser: BlockAnnotationParsing
    private let xcodeProjModifierFactory: XcodeProjModifierMaking

    public convenience init() {
        self.init(
            clock: ContinuousClock(),
            blockAnnotationParser: BlockAnnotationParser(),
            xcodeProjModifierFactory: XcodeProjModifierFactory()
        )
    }

    init(
        clock: TimeMeasuring,
        blockAnnotationParser: BlockAnnotationParsing,
        xcodeProjModifierFactory: XcodeProjModifierMaking
    ) {
        self.clock = clock
        self.blockAnnotationParser = blockAnnotationParser
        self.xcodeProjModifierFactory = xcodeProjModifierFactory
    }

    func generate(
        from parsingResult: inout ParsingResult,
        using templates: [Template],
        config: Configuration
    ) throws {
        guard config.output.isNotEmpty else {
            throw Error.noOutput
        }

        guard templates.isNotEmpty else {
            throw Error.noTemplates
        }

        var output = config.output
        if !output.isRepresentingDirectory {
            logger.warning("The output path targets a single file. Continuing using its directory instead.")
            output = output.parent()
        }

        let elapsedTime = try clock.measure {
            let xcodeProjModifier = try xcodeProjModifierFactory.makeModifier(from: config)

            for template in templates {
                let (content, sourceChanges) = try generate(from: parsingResult, using: template, config: config)
                updateRanges(in: &parsingResult, sourceChanges: sourceChanges)
                let outputPath = output.appending(template.path.generatedFileName)
                try write(content, to: outputPath)

                try xcodeProjModifier?.addSourceFile(path: outputPath)
            }

            for (outputPath, content) in fileAnnotatedContent {
                try write(content.joined(separator: "\n"), to: outputPath)

                try xcodeProjModifier?.addSourceFile(path: outputPath)
            }

            try xcodeProjModifier?.save()
        }

        logger.info("Code generation finished in \(elapsedTime)")
    }

    private func generate(from parsingResult: ParsingResult, using template: Template, config: Configuration) throws -> GenerationResult {
        let content = try template.render(.init(
            parserResult: parsingResult.parserResult,
            types: parsingResult.types,
            functions: parsingResult.functions,
            arguments: config.arguments
        ))
        return try processAnnotations(in: content, for: parsingResult, config: config)
    }

    private func processAnnotations(in content: String, for parsingResult: ParsingResult, config: Configuration) throws -> GenerationResult {
        var content = content
        processFileAnnotations(in: &content, config: config)
        let sourceChanges: [SourceChange]
        (content, sourceChanges) = try processInlineAnnotations(in: content, for: parsingResult, config: config)
        content = blockAnnotationParser.removingEmptyAnnotations(from: content)
        return (content, sourceChanges)
    }

    private func processFileAnnotations(in content: inout String, config: Configuration) {
        let annotations = blockAnnotationParser.parseAnnotations("file", content: content, aggregate: true, forceParse: config.forceParse)
        annotations
            .annotatedRanges
            .map { ($0, $1) }
            .forEach { filePath, ranges in
                let generatedBody = ranges.map { content.bridge().substring(with: $0.range) }.joined(separator: "\n")
                let path = config.output + (Path(filePath).extension == nil ? "\(filePath).generated.swift" : filePath)
                var fileContents = fileAnnotatedContent[path] ?? []
                fileContents.append(generatedBody)
                fileAnnotatedContent[path] = fileContents
            }
        content = annotations.content
    }

    private func processInlineAnnotations(in content: String, for parsingResult: ParsingResult, config: Configuration) throws -> GenerationResult {
        var (annotatedRanges, rangesToReplace) = blockAnnotationParser.annotationRanges("inline", content: content, forceParse: config.forceParse)

        typealias MappedInlineAnnotations = (
            range: NSRange,
            filePath: String,
            rangeInFile: NSRange,
            toInsert: String,
            indentation: String
        )

        var sourceChanges: [SourceChange] = []

        try annotatedRanges
            .map { (key: $0, range: $1[0].range) }
            .compactMap { key, range -> MappedInlineAnnotations? in
                let generatedBody = content.bridge().substring(with: range)

                if let (filePath, inlineRanges, inlineIndentations) = parsingResult.inlineRanges.first(where: { $0.ranges[key] != nil }) {
                    // swiftlint:disable:next force_unwrapping
                    return MappedInlineAnnotations(range, filePath, inlineRanges[key]!, generatedBody, inlineIndentations[key] ?? "")
                }

                guard let autoRange = key.range(of: "auto:") else {
                    rangesToReplace.remove(range)
                    return nil
                }

                enum AutoType: String {
                    case after = "after-"
                    case normal = ""
                }

                let autoKey = key[..<autoRange.lowerBound]
                let autoType = AutoType(rawValue: String(autoKey)) ?? .normal

                let autoTypeName = key[autoRange.upperBound ..< key.endIndex].components(separatedBy: ".").dropLast().joined(separator: ".")
                var toInsert = "\n// sourcery:inline:\(key)\n\(generatedBody)// sourcery:end"

                guard let definition = parsingResult.types.types.first(where: { $0.name == autoTypeName }),
                      let filePath = definition.path,
                      let path = definition.path.map({ Path($0) }),
                      let contents = try? path.read(.utf8),
                      let bodyRange = bodyRange(for: definition, contentsView: StringView(contents))
                else {
                    rangesToReplace.remove(range)
                    return nil
                }
                let bodyEndRange = NSRange(location: NSMaxRange(bodyRange), length: 0)
                let bodyEndLineRange = contents.bridge().lineRange(for: bodyEndRange)
                let bodyEndLine = contents.bridge().substring(with: bodyEndLineRange)
                let indentRange: NSRange? = if !bodyEndLine.contains("{") {
                    (bodyEndLine as NSString).rangeOfCharacter(from: .whitespacesAndNewlines.inverted)
                } else {
                    nil
                }
                let rangeInFile: NSRange

                switch autoType {
                case .after:
                    rangeInFile = NSRange(location: max(bodyRange.location, bodyEndLineRange.location) + 1, length: 0)
                case .normal:
                    rangeInFile = NSRange(location: max(bodyRange.location, bodyEndLineRange.location), length: 0)
                    toInsert += "\n"
                }

                let indent = String(repeating: " ", count: (indentRange?.location ?? 0) + config.baseIndentation)
                return MappedInlineAnnotations(range, filePath, rangeInFile, toInsert, indent)
            }
            .sorted { lhs, rhs in
                lhs.rangeInFile.location > rhs.rangeInFile.location
            }
            .forEach { _, filePath, rangeInFile, toInsert, indentation in
                let path = Path(filePath).unlinked
                let content = try path.read(.utf8)
                let snippet = indent(toInsert: toInsert, indentation: indentation)
                let newContent = content.bridge().replacingCharacters(in: rangeInFile, with: snippet)

                if newContent != content {
                    try path.write(newContent)
                }

                let newLength = snippet.bridge().length

                sourceChanges.append((
                    path: filePath,
                    rangeInFile: rangeInFile,
                    newRangeInFile: NSRange(location: rangeInFile.location, length: newLength)
                ))
            }

        var bridged = content.bridge()

        rangesToReplace
            .sorted { $0.location > $1.location }
            .forEach {
                bridged = bridged.replacingCharacters(in: $0, with: "") as NSString
            }
        return (bridged as String, sourceChanges)
    }

    private func bodyRange(for type: Type, contentsView: StringView) -> NSRange? {
        guard let bytesRange = type.bodyBytesRange else { return nil }
        return contentsView.byteRangeToNSRange(ByteRange(location: ByteCount(bytesRange.offset), length: ByteCount(bytesRange.length)))
    }

    private func updateRanges(in parsingResult: inout ParsingResult, sourceChanges: [SourceChange]) {
        for (path, rangeInFile, newRangeInFile) in sourceChanges {
            if let inlineRangesIndex = parsingResult.inlineRanges.firstIndex(where: { $0.file == path }) {
                let inlineRanges = parsingResult.inlineRanges[inlineRangesIndex].ranges
                    .mapValues { inlineRange -> NSRange in
                        let change = NSRange(
                            location: newRangeInFile.location,
                            length: newRangeInFile.length - rangeInFile.length
                        )
                        return inlineRange.changingContent(change)
                    }
                parsingResult.inlineRanges[inlineRangesIndex].ranges = inlineRanges
            }

            func stringViewForContent(at path: String) -> StringView? {
                do {
                    return try StringView(Path(path).read(.utf8))
                } catch {
                    return nil
                }
            }

            for type in parsingResult.types.types {
                guard
                    type.path == path,
                    let bytesRange = type.bodyBytesRange,
                    let completeDeclarationRange = type.completeDeclarationRange,
                    let content = stringViewForContent(at: path),
                    let byteRangeInFile = content.NSRangeToByteRange(rangeInFile),
                    let newByteRangeInFile = content.NSRangeToByteRange(newRangeInFile)
                else {
                    continue
                }

                let change = ByteRange(
                    location: newByteRangeInFile.location,
                    length: newByteRangeInFile.length - byteRangeInFile.length
                )
                type.bodyBytesRange = bytesRange.changingContent(change)
                type.completeDeclarationRange = completeDeclarationRange.changingContent(change)
            }
        }
    }

    private func indent(toInsert: String, indentation: String) -> String {
        guard indentation.isEmpty == false else {
            return toInsert
        }
        let lines = toInsert.components(separatedBy: "\n")
        return lines.enumerated()
            .map { index, line in
                guard !line.isEmpty else {
                    return line
                }
                return index == lines.count - 1 ? line : indentation + line
            }
            .joined(separator: "\n")
    }

    private func write(_ content: String, to outputPath: Path) throws {
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            if outputPath.exists {
                logger.warning("Removing \(outputPath.relativeToCurrent) as its generated content is empty.")
                do { try outputPath.delete() } catch { logger.error("\(error)") }
            } else {
                logger.warning("Skipping \(outputPath.relativeToCurrent) as its generated content is empty.")
            }
            return
        }

        let outputPath = outputPath.unlinked

        logger.info("Generating \(outputPath.relativeToCurrent)")

        let content = outputPath.extension == "swift" ? .generatedHeader + content : content

        if !outputPath.parent().exists {
            try outputPath.parent().mkpath()
        }
        try outputPath.writeIfChanged(content)
    }

    enum Error: Swift.Error, Equatable {
        case noOutput
        case noTemplates
    }
}
