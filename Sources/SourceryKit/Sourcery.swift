import FileSystemEvents
import Foundation
import PathKit
import SourceryRuntime
import XcodeProj

public class Sourcery {
    public static let version = SourceryVersion.current.value

    private let verbose: Bool
    private let watcherEnabled: Bool
    private let cacheDisabled: Bool
    private let buildPath: Path?
    private let serialParse: Bool
    
    private let swiftGenerator: SwiftGenerator
    private let swiftParser: SwiftParser

    public init(
        verbose: Bool = false,
        watcherEnabled: Bool = false,
        cacheDisabled: Bool = false,
        buildPath: Path? = nil,
        serialParse: Bool = false,
        swiftGenerator: SwiftGenerator = SwiftGenerator(),
        swiftParser: SwiftParser = SwiftParser()
    ) {
        self.verbose = verbose
        self.watcherEnabled = watcherEnabled
        self.cacheDisabled = cacheDisabled
        self.buildPath = buildPath
        self.serialParse = serialParse
        self.swiftGenerator = swiftGenerator
        self.swiftParser = swiftParser
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
        var parsingResult = try swiftParser.parseSources(from: config, requiresFileParserCopy: hasSwiftTemplates, serialParse: serialParse, cacheDisabled: cacheDisabled)
        let templates = try loadTemplates(from: config)
        try swiftGenerator.generate(from: &parsingResult, using: templates, to: config.output, config: config)
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
                    try self.swiftGenerator.generate(
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
