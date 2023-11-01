import Foundation
import PathKit
import SourceryRuntime

public class SwiftParser {
    typealias ParserWrapper = (path: Path, parse: () throws -> FileParserResult?)

    private let syntaxParser: SwiftSyntaxParsing

    public init() {
        syntaxParser = SwiftSyntaxParser()
    }

    func parseSources(from config: Configuration) throws -> ParsingResult {
        var inlineRanges: [(file: String, ranges: [String: Range<Substring.Index>], indentations: [String: String])] = []
        var allResults: [(changed: Bool, result: FileParserResult)] = []

        for (index, sourceFile) in config.sources.enumerated() {
            let fileList = sourceFile.path.isDirectory ? try sourceFile.path.recursiveChildren() : [sourceFile.path]
            let singleFileParser: [ParserWrapper] = fileList
                .filter(\.isSwiftSourceFile)
                .map { [syntaxParser] path in
                    (path: path, parse: {
                        guard path.exists else {
                            return nil
                        }

                        let content = try path.read(.utf8)
                        let status = Verifier.canParse(content: content, path: path, forceParse: config.forceParse)
                        switch status {
                        case .containsConflictMarkers:
                            throw Error.containsMergeConflictMarkers
                        case .isCodeGenerated:
                            return nil
                        case .approved:
                            return syntaxParser.parse(
                                content,
                                path: path,
                                module: config.sources[index].module,
                                forceParse: config.forceParse,
                                parseDocumentation: config.parseDocumentation
                            )
                        }
                    })
                }

            var lastError: Swift.Error?

            let results: [(changed: Bool, result: FileParserResult)] = singleFileParser.parallelCompactMap { parser in
                do {
                    let cachePath: Path? = config.cacheDisabled ? nil : .cachesDir(sourcePath: sourceFile.path, basePath: config.cacheBasePath)
                    return try self.loadOrParse(parser: parser, cachePath: cachePath)
                } catch {
                    lastError = error
                    logger.error("Unable to parse \(parser.path), error \(error)")
                    return nil
                }
            }

            if let error = lastError {
                throw error
            }

            if !results.isEmpty {
                allResults.append(contentsOf: results)
            }
        }

        var allTypealiases: [Typealias] = []
        var allTypes: [Type] = []
        var allFunctions: [SourceryMethod] = []

        for pair in allResults {
            let next = pair.result
            allTypealiases += next.typealiases
            allTypes += next.types
            allFunctions += next.functions

            inlineRanges.append((next.path!, next.inlineRanges, next.inlineIndentations))
        }

        let parserResult = FileParserResult(path: nil, module: nil, types: allTypes, functions: allFunctions, typealiases: allTypealiases)

        // ! All files have been scanned, time to join extensions with base class
        let (types, functions, typealiases) = Composer.uniqueTypesAndFunctions(parserResult)

        let changedFiles = allResults
            .filter(\.changed)
            .compactMap(\.result.path)

        logger.info("Found \(types.count, singular: "type", plural: "types") in \(allResults.count, singular: "file", plural: "files").")

        if !config.cacheDisabled, logger.level == .verbose, changedFiles.isNotEmpty {
            logger.verbose("\(changedFiles.count) changed from last run:")
            changedFiles.map { Path($0).relativeToCurrent }.forEach {
                logger.verbose("\($0)")
            }
        } else if !config.cacheDisabled {
            logger.info("\(changedFiles.count, singular: "file", plural: "files") changed from last run.")
        }

        return .init(
            parserResult: parserResult,
            types: Types(types: types, typealiases: typealiases),
            functions: functions,
            inlineRanges: inlineRanges
        )
    }

    private func loadOrParse(parser: ParserWrapper, cachePath: Path?) throws -> (changed: Bool, result: FileParserResult)? {
        guard let cachePath else {
            return try parser.parse().map { (changed: true, result: $0) }
        }

        let path = parser.path
        let artifactsPath = cachePath + "\(path.string.hash).srf"

        guard
            artifactsPath.exists,
            let modifiedDate = path.modificationDate,
            let unarchived = loadArtifacts(path: artifactsPath, modifiedDate: modifiedDate)
        else {
            guard let result = try parser.parse() else {
                return nil
            }

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: result, requiringSecureCoding: false)
                try artifactsPath.write(data)
            } catch {
                fatalError("Unable to save artifacts for \(path) under \(artifactsPath), error: \(error)")
            }

            return (changed: true, result: result)
        }

        return (changed: false, result: unarchived)
    }

    private func loadArtifacts(path: Path, modifiedDate: Date) -> FileParserResult? {
        guard
            let data = try? path.read(),
            let result = try? NSKeyedUnarchiver.unarchivedRootObject(ofClass: FileParserResult.self, from: data),
            result.modifiedDate == modifiedDate
        else {
            return nil
        }
        return result
    }

    enum Error: Swift.Error {
        case containsMergeConflictMarkers
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ count: Int, singular: String, plural: String) {
        if count == 1 {
            appendLiteral("\(count) \(singular)")
        } else {
            appendLiteral("\(count) \(plural)")
        }
    }
}
