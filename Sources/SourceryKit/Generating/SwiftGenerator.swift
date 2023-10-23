import Foundation
import PathKit
import SourceryRuntime

public class SwiftGenerator {
    typealias SourceChange = (path: String, rangeInFile: NSRange, newRangeInFile: NSRange)
    typealias GenerationResult = (String, [SourceChange])

    // content annotated with file annotations per file path to write it to
    private var fileAnnotatedContent: [Path: [String]] = [:]

    private let clock: TimeMeasuring

    public convenience init() {
        self.init(clock: ContinuousClock())
    }

    init(clock: TimeMeasuring) {
        self.clock = clock
    }

    func generate(
        from parsingResult: inout ParsingResult,
        using templates: [Template],
        to output: Output,
        config: Configuration
    ) throws {
        guard output.isNotEmpty else {
            throw Error.noOutput
        }

        guard templates.isNotEmpty else {
            throw Error.noTemplates
        }

        logger.info("Generating code...")

        let elapsedTime = try clock.measure {
            if output.isRepresentingDirectory {
                try templates.forEach { template in
                    let (result, sourceChanges) = try generate(template, forParsingResult: parsingResult, config: config)
                    updateRanges(in: &parsingResult, sourceChanges: sourceChanges)
                    let outputPath = output.path + template.sourcePath.generatedPath
                    try self.output(result, to: outputPath)

                    if let linkTo = output.linkTo {
                        linkTo.targets.forEach { target in
                            link(outputPath, to: linkTo, target: target)
                        }
                    }
                }
            } else {
                let result = try templates.reduce((contents: "", parsingResult: parsingResult)) { state, template in
                    var (result, parsingResult) = state
                    let (generatedCode, sourceChanges) = try generate(template, forParsingResult: parsingResult, config: config)
                    result += "\n" + generatedCode
                    updateRanges(in: &parsingResult, sourceChanges: sourceChanges)
                    return (result, parsingResult)
                }
                parsingResult = result.parsingResult
                try self.output(result.contents, to: output.path)

                if let linkTo = output.linkTo {
                    linkTo.targets.forEach { target in
                        link(output.path, to: linkTo, target: target)
                    }
                }
            }

            try fileAnnotatedContent.forEach { path, contents in
                try self.output(contents.joined(separator: "\n"), to: path)

                if let linkTo = output.linkTo {
                    linkTo.targets.forEach { target in
                        link(path, to: linkTo, target: target)
                    }
                }
            }

            if let linkTo = output.linkTo {
                try linkTo.project.writePBXProj(path: linkTo.projectPath, outputSettings: .init())
            }
        }

        logger.info("Code generation finished in \(elapsedTime)")
    }

    private func generate(_ template: Template, forParsingResult parsingResult: ParsingResult, config: Configuration) throws -> GenerationResult {
        let generationStart = currentTimestamp()
        let result = try template.render(.init(
            parserResult: parsingResult.parserResult,
            types: parsingResult.types,
            functions: parsingResult.functions,
            arguments: config.arguments
        ))
        logger.benchmark("\tGenerating \(template.sourcePath.lastComponent) took \(currentTimestamp() - generationStart)")
        return try processRanges(in: parsingResult, result: result, config: config)
    }

    private func processRanges(in parsingResult: ParsingResult, result: String, config: Configuration) throws -> GenerationResult {
        let start = currentTimestamp()
        defer {
            logger.benchmark("\t\tProcessing Ranges took \(currentTimestamp() - start)")
        }
        var result = result
        result = processFileRanges(for: parsingResult, in: result, config: config)
        let sourceChanges: [SourceChange]
        (result, sourceChanges) = try processInlineRanges(for: parsingResult, in: result, config: config)
        return (TemplateAnnotationsParser.removingEmptyAnnotations(from: result), sourceChanges)
    }

    private func processFileRanges(for parsingResult: ParsingResult, in contents: String, config: Configuration) -> String {
        let files = TemplateAnnotationsParser.parseAnnotations("file", contents: contents, aggregate: true, forceParse: config.forceParse)

        files
            .annotatedRanges
            .map { ($0, $1) }
            .forEach { filePath, ranges in
                let generatedBody = ranges.map { contents.bridge().substring(with: $0.range) }.joined(separator: "\n")
                let path = config.output.path + (Path(filePath).extension == nil ? "\(filePath).generated.swift" : filePath)
                var fileContents = fileAnnotatedContent[path] ?? []
                fileContents.append(generatedBody)
                fileAnnotatedContent[path] = fileContents
            }
        return files.contents
    }

    private func processInlineRanges(for parsingResult: ParsingResult, in contents: String, config: Configuration) throws -> GenerationResult {
        var (annotatedRanges, rangesToReplace) = TemplateAnnotationsParser.annotationRanges("inline", contents: contents, forceParse: config.forceParse)

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
            .compactMap { (key, range) -> MappedInlineAnnotations? in
                let generatedBody = contents.bridge().substring(with: range)

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

                let autoTypeName = key[autoRange.upperBound..<key.endIndex].components(separatedBy: ".").dropLast().joined(separator: ".")
                var toInsert = "\n// sourcery:inline:\(key)\n\(generatedBody)// sourcery:end"

                guard let definition = parsingResult.types.types.first(where: { $0.name == autoTypeName }),
                    let filePath = definition.path,
                    let path = definition.path.map({ Path($0) }),
                    let contents = try? path.read(.utf8),
                    let bodyRange = bodyRange(for: definition, contentsView: StringView(contents)) else {
                        rangesToReplace.remove(range)
                        return nil
                }
                let bodyEndRange = NSRange(location: NSMaxRange(bodyRange), length: 0)
                let bodyEndLineRange = contents.bridge().lineRange(for: bodyEndRange)
                let bodyEndLine = contents.bridge().substring(with: bodyEndLineRange)
                let indentRange: NSRange?
                if !bodyEndLine.contains("{") {
                    indentRange = (bodyEndLine as NSString).rangeOfCharacter(from: .whitespacesAndNewlines.inverted)
                } else {
                    indentRange = nil
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
                let path = Path(filePath)
                let content = try path.read(.utf8)
                let newContent = indent(toInsert: toInsert, indentation: indentation)

                try path.write(content.bridge().replacingCharacters(in: rangeInFile, with: newContent))

                let newLength = newContent.bridge().length

                sourceChanges.append((
                    path: filePath,
                    rangeInFile: rangeInFile,
                    newRangeInFile: NSRange(location: rangeInFile.location, length: newLength)
                ))
            }

        var bridged = contents.bridge()

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
                    return StringView(try Path(path).read(.utf8))
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

    private func link(_ output: Path, to linkTo: Output.LinkTo, target targetName: String) {
        guard let target = linkTo.project.target(named: targetName) else {
            logger.warning("Unable to find target \(targetName)")
            return
        }

        let sourceRoot = linkTo.projectPath.parent()

        guard let fileGroup = linkTo.project.createGroupIfNeeded(named: linkTo.group, sourceRoot: sourceRoot) else {
            logger.warning("Unable to create group \(String(describing: linkTo.group))")
            return
        }

        do {
            try linkTo.project.addSourceFile(at: output, toGroup: fileGroup, target: target, sourceRoot: sourceRoot)
        } catch {
            logger.warning("Failed to link file at \(output) to \(linkTo.projectPath). \(error)")
        }
    }

    private func output(_ content: String, to outputPath: Path) throws {
        let resultIsEmpty = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        var content = content
        if !resultIsEmpty, outputPath.extension == "swift" {
            content = .generatedHeader + content
        }

        if resultIsEmpty {
            if outputPath.exists {
                logger.verbose("Removing \(outputPath) as its generated content is empty.")
                do { try outputPath.delete() } catch { logger.error("\(error)") }
            } else {
                logger.verbose("Skipping \(outputPath) as its generated content is empty.")
            }
        } else {
            if !outputPath.parent().exists {
                try outputPath.parent().mkpath()
            }
            try outputPath.writeIfChanged(content)
        }
    }

    enum Error: Swift.Error, Equatable {
        case noOutput
        case noTemplates
    }
}
