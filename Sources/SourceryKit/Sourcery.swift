import FileSystemEvents
import Foundation
import PathKit
import SourceryRuntime
import XcodeProj

public class Sourcery {
    public static let version = SourceryVersion.current.value

    enum Error: Swift.Error {
        case containsMergeConflictMarkers
    }

    private let verbose: Bool
    private let watcherEnabled: Bool
    private let cacheDisabled: Bool
    private let buildPath: Path?
    private let serialParse: Bool
    private let generator: SwiftGenerator

    public init(
        verbose: Bool = false,
        watcherEnabled: Bool = false,
        cacheDisabled: Bool = false,
        buildPath: Path? = nil,
        serialParse: Bool = false,
        generator: SwiftGenerator = SwiftGenerator()
    ) {
        self.verbose = verbose
        self.watcherEnabled = watcherEnabled
        self.cacheDisabled = cacheDisabled
        self.buildPath = buildPath
        self.serialParse = serialParse
        self.generator = generator
    }

    @discardableResult
    public func processConfiguration(_ config: Configuration) throws -> [FSEventStream] {
        let hasSwiftTemplates = config.templates.allPaths.contains { $0.extension == "swifttemplate" }

        let parserResult = try process(config, hasSwiftTemplates)

        return watcherEnabled ? createWatchers(
            config: config,
            parserResult: parserResult,
            hasSwiftTemplates: hasSwiftTemplates
        ) : []
    }

    private func process(_ config: Configuration, _ hasSwiftTemplates: Bool) throws -> ParsingResult {
        var parsingResult = try parseSources(from: config, requiresFileParserCopy: hasSwiftTemplates)
        let templates = try loadTemplates(from: config)
        try generator.generate(from: &parsingResult, using: templates, to: config.output, config: config)
        return parsingResult
    }

    private func loadTemplates(from config: Configuration) throws -> [Template] {
        let start = currentTimestamp()
        logger.info("Loading templates...")

        let templates: [Template] = try config.templates.allPaths.filter(\.isTemplateFile).map {
            if $0.extension == "swifttemplate" {
                let cachePath = cachesDir(sourcePath: $0, basePath: config.cacheBasePath)
                return try SwiftTemplate(path: $0, cachePath: cachePath, version: type(of: self).version, buildPath: buildPath)
            } else {
                return try StencilTemplate(path: $0)
            }
        }

        logger.info("Loaded \(templates.count) templates.")
        logger.benchmark("\tLoading took \(currentTimestamp() - start)")

        return templates
    }

    private func createWatchers(
        config: Configuration,
        parserResult: ParsingResult,
        hasSwiftTemplates: Bool
    ) -> [FSEventStream] {
        var result = parserResult

        let sourcePaths = switch config.sources {
        case let .paths(paths):
            paths
        case let .projects(projects):
            Paths(include: projects.map(\.root), exclude: projects.flatMap(\.exclude))
        }

        logger.info("Starting watching sources.")

        let sourceWatchers = topPaths(from: sourcePaths.allPaths).compactMap { path in
            FSEventStream(path: path.string) { events in
                let eventPaths: [Path] = events
                    .filter { $0.flags.contains(.isFile) }
                    .compactMap {
                        let path = Path($0.path)
                        return path.isSwiftSourceFile ? path : nil
                    }

                var pathThatForcedRegeneration: Path?
                for path in eventPaths {
                    guard let file = try? path.read(.utf8) else { continue }
                    if !file.hasPrefix(.generatedHeader) {
                        pathThatForcedRegeneration = path
                        break
                    }
                }

                if let path = pathThatForcedRegeneration {
                    do {
                        logger.info("Source changed at \(path.string)")
                        result = try self.process(config, hasSwiftTemplates)
                    } catch {
                        logger.error(error)
                    }
                }
            }
        }

        logger.info("Starting watching templates.")

        let templateWatchers = topPaths(from: config.templates.allPaths).compactMap { path in
            FSEventStream(path: path.string) { events in
                let events = events.filter { $0.flags.contains(.isFile) && Path($0.path).isTemplateFile }

                if events.isEmpty { return }

                do {
                    if events.count == 1 {
                        logger.info("Template changed \(events[0].path)")
                    } else {
                        logger.info("Templates changed: ")
                    }
                    let templates = try self.loadTemplates(from: config)
                    try self.generator.generate(
                        from: &result,
                        using: templates,
                        to: config.output,
                        config: config
                    )
                } catch {
                    logger.error(error)
                }
            }
        }

        return Array([sourceWatchers, templateWatchers].joined())
    }

    private func topPaths(from paths: [Path]) -> [Path] {
        var top: [(Path, [Path])] = []
        paths.forEach { path in
            // See if its already contained by the topDirectories
            guard top.first(where: { (_, children) -> Bool in
                return children.contains(path)
            }) == nil else { return }

            if path.isDirectory {
                top.append((path, (try? path.recursiveChildren()) ?? []))
            } else {
                let dir = path.parent()
                let children = (try? dir.recursiveChildren()) ?? []
                if children.contains(path) {
                    top.append((dir, children))
                } else {
                    top.append((path, []))
                }
            }
        }

        return top.map { $0.0 }
    }

    /// This function should be used to retrieve the path to the cache instead of `Path.cachesDir`,
    /// as it considers the `--cacheDisabled` and `--cacheBasePath` command line parameters.
    fileprivate func cachesDir(sourcePath: Path, basePath: Path, createIfMissing: Bool = true) -> Path? {
        cacheDisabled ? nil : .cachesDir(sourcePath: sourcePath, basePath: basePath, createIfMissing: createIfMissing)
    }

    /// Remove the existing cache artifacts if it exists.
    /// Currently this is only called from tests, and the `--cacheDisabled` and `--cacheBasePath` command line parameters are not considered.
    ///
    /// - Parameter sources: paths of the sources you want to delete the
    static func removeCache(for sources: [Path], cacheDisabled: Bool = false, cacheBasePath: Path? = nil) {
        if cacheDisabled {
            return
        }
        sources.forEach { path in
            let cacheDir = Path.cachesDir(sourcePath: path, basePath: cacheBasePath, createIfMissing: false)
            _ = try? cacheDir.delete()
        }
    }
}

// MARK: - Parsing

extension Sourcery {
    typealias ParserWrapper = (path: Path, parse: () throws -> FileParserResult?)

    private func parseSources(from config: Configuration, requiresFileParserCopy: Bool) throws -> ParsingResult {
        switch config.sources {
        case let .paths(paths):
            return try parse(
                sources: paths.include,
                excludes: paths.exclude,
                config: config,
                modules: nil,
                requiresFileParserCopy: requiresFileParserCopy
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
                requiresFileParserCopy: requiresFileParserCopy
            )
        }
    }

    private func parse(
        sources: [Path],
        excludes: [Path] = [],
        config: Configuration,
        modules: [String]?,
        requiresFileParserCopy: Bool
    ) throws -> ParsingResult {
        if let modules {
            precondition(sources.count == modules.count, "There should be module for each file to parse")
        }

        let startScan = currentTimestamp()
        logger.info("Scanning sources...")

        var inlineRanges = [(file: String, ranges: [String: NSRange], indentations: [String: String])]()
        var allResults = [(changed: Bool, result: FileParserResult)]()

        let excludeSet = Set(
            excludes
                .map { $0.isDirectory ? try? $0.recursiveChildren() : [$0] }
                .compactMap { $0 }
                .flatMap { $0 }
        )

        try sources.enumerated().forEach { index, sourcePath in
            let fileList = sourcePath.isDirectory ? try sourcePath.recursiveChildren() : [sourcePath]
            let parserGenerator: [ParserWrapper] = fileList
                .filter { $0.isSwiftSourceFile }
                .filter {
                    return !excludeSet.contains($0)
                }
                .map { path in
                    return (path: path, parse: {
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
                    return try self.loadOrParse(parser: parser, cachesPath: self.cachesDir(sourcePath: sourcePath, basePath: config.cacheBasePath))
                } catch {
                    lastError = error
                    logger.error("Unable to parse \(parser.path), error \(error)")
                    return nil
                }
            }

            let results: [(changed: Bool, result: FileParserResult)]
            if serialParse {
                results = parserGenerator.compactMap(transform)
            } else {
                results = parserGenerator.parallelCompactMap(transform: transform)
            }

            if let error = lastError {
                throw error
            }

            if !results.isEmpty {
                allResults.append(contentsOf: results)
            }
        }

        logger.benchmark("\tloadOrParse: \(currentTimestamp() - startScan)")
        let reduceStart = currentTimestamp()

        var allTypealiases = [Typealias]()
        var allTypes = [Type]()
        var allFunctions = [SourceryMethod]()

        for pair in allResults {
            let next = pair.result
            allTypealiases += next.typealiases
            allTypes += next.types
            allFunctions += next.functions

            // swiftlint:disable:next force_unwrapping
            inlineRanges.append((next.path!, next.inlineRanges, next.inlineIndentations))
        }

        let parserResult = FileParserResult(path: nil, module: nil, types: allTypes, functions: allFunctions, typealiases: allTypealiases)

        var parserResultCopy: FileParserResult?
        if requiresFileParserCopy {
            let data = try NSKeyedArchiver.archivedData(withRootObject: parserResult, requiringSecureCoding: false)
            parserResultCopy = try NSKeyedUnarchiver.unarchivedRootObject(ofClass: FileParserResult.self, from: data)
        }

        let uniqueTypeStart = currentTimestamp()

        // ! All files have been scanned, time to join extensions with base class
        let (types, functions, typealiases) = Composer.uniqueTypesAndFunctions(parserResult)


        let filesThatHadToBeParsed = allResults
            .filter { $0.changed }
            .compactMap { $0.result.path }

        logger.benchmark("\treduce: \(uniqueTypeStart - reduceStart)\n\tcomposer: \(currentTimestamp() - uniqueTypeStart)\n\ttotal: \(currentTimestamp() - startScan)")
        logger.info("Found \(types.count) types in \(allResults.count) files, \(filesThatHadToBeParsed.count) changed from last run.")

        if !filesThatHadToBeParsed.isEmpty, (filesThatHadToBeParsed.count < 50 || logger.level == .verbose) {
            let files = filesThatHadToBeParsed
                .joined(separator: "\n")
            logger.info("Files changed:\n\(files)")
        }
        return .init(
            parserResult: parserResultCopy,
            types: Types(types: types, typealiases: typealiases),
            functions: functions,
            inlineRanges: inlineRanges
        )
    }

    private func loadOrParse(parser: ParserWrapper, cachesPath: @autoclosure () -> Path?) throws -> (changed: Bool, result: FileParserResult)? {
        guard let cachesPath = cachesPath() else {
            return try parser.parse().map { (changed: true, result: $0) }
        }

        let path = parser.path
        let artifactsPath = cachesPath + "\(path.string.hash).srf"

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
            result.sourceryVersion == Sourcery.version,
            result.modifiedDate == modifiedDate
        else {
            return nil
        }
        return result
    }
}
