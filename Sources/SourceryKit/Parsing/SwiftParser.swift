import Foundation
import PathKit
import SourceryRuntime

public class SwiftParser {
    typealias ParserWrapper = (path: Path, parse: () throws -> FileParserResult?)

    public init() {}

    func parseSources(
        from config: Configuration,
        cacheDisabled: Bool
    ) throws -> ParsingResult {
        let requiresFileParserCopy = config.templates.allPaths.contains { $0.extension == "swifttemplate" }

        switch config.sources {
        case let .paths(paths):
            return try parse(
                sources: paths.include,
                excludes: paths.exclude,
                config: config,
                modules: nil,
                requiresFileParserCopy: requiresFileParserCopy,
                cacheDisabled: cacheDisabled
            )
        case let .projects(projects):
            var paths: [Path] = []
            var modules: [String] = []
            projects.forEach { project in
                project.targets.forEach { target in
                    guard let projectTarget = project.file.target(named: target.name) else { return }

                    let files = project.file.sourceFilesPaths(target: projectTarget, sourceRoot: project.root)
                    files.forEach { file in
                        guard !project.exclude.contains(file) else { return }
                        paths.append(file)
                        modules.append(target.module)
                    }
                    for framework in target.xcframeworks {
                        paths.append(framework.swiftInterfacePath)
                        modules.append(target.module)
                    }
                }
            }
            return try parse(
                sources: paths,
                config: config,
                modules: modules,
                requiresFileParserCopy: requiresFileParserCopy,
                cacheDisabled: cacheDisabled
            )
        }
    }

    private func parse(
        sources: [Path],
        excludes: [Path] = [],
        config: Configuration,
        modules: [String]?,
        requiresFileParserCopy: Bool,
        cacheDisabled: Bool
    ) throws -> ParsingResult {
        if let modules {
            precondition(sources.count == modules.count, "There should be module for each file to parse")
        }

        var inlineRanges: [(file: String, ranges: [String: NSRange], indentations: [String: String])] = []
        var allResults: [(changed: Bool, result: FileParserResult)] = []

        let excludeSet = Set(
            excludes
                .map { $0.isDirectory ? try? $0.recursiveChildren() : [$0] }
                .compactMap { $0 }
                .flatMap { $0 }
        )

        for (index, sourcePath) in sources.enumerated() {
            let fileList = sourcePath.isDirectory ? try sourcePath.recursiveChildren() : [sourcePath]
            let parserGenerator: [ParserWrapper] = fileList
                .filter(\.isSwiftSourceFile)
                .filter { !excludeSet.contains($0) }
                .map { path in
                    (path: path, parse: {
                        let module = modules?[index]

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
                            return try makeParser(
                                for: content,
                                forceParse: config.forceParse,
                                parseDocumentation: config.parseDocumentation,
                                path: path,
                                module: module
                            ).parse()
                        }
                    })
                }

            var lastError: Swift.Error?

            let transform: (ParserWrapper) -> (changed: Bool, result: FileParserResult)? = { parser in
                do {
                    let cachePath: Path? = cacheDisabled ? nil : .cachesDir(sourcePath: sourcePath, basePath: config.cacheBasePath)
                    return try self.loadOrParse(parser: parser, cachePath: cachePath)
                } catch {
                    lastError = error
                    logger.error("Unable to parse \(parser.path), error \(error)")
                    return nil
                }
            }

            let results: [(changed: Bool, result: FileParserResult)] = parserGenerator.parallelCompactMap(transform: transform)

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

        var parserResultCopy: FileParserResult?
        if requiresFileParserCopy {
            let data = try NSKeyedArchiver.archivedData(withRootObject: parserResult, requiringSecureCoding: false)
            parserResultCopy = try NSKeyedUnarchiver.unarchivedRootObject(ofClass: FileParserResult.self, from: data)
        }

        // ! All files have been scanned, time to join extensions with base class
        let (types, functions, typealiases) = Composer.uniqueTypesAndFunctions(parserResult)

        let changedFiles = allResults
            .filter(\.changed)
            .compactMap(\.result.path)

        logger.info("Found \(types.count) types in \(allResults.count) files, \(changedFiles.count) changed from last run.")

        if logger.level == .verbose, changedFiles.isNotEmpty {
            logger.verbose("Files changed:")
            changedFiles.map { Path($0).relativeToCurrent }.forEach {
                logger.verbose("\($0)")
            }
        }
        return .init(
            parserResult: parserResultCopy,
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
            let modifiedDate = path.modifiedDate,
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
