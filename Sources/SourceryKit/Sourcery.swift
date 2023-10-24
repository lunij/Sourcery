import FileSystemEvents
import Foundation
import PathKit
import SourceryRuntime
import XcodeProj

public class Sourcery {
    public static let version = "2.0.2"

    private let watcherEnabled: Bool
    private let cacheDisabled: Bool
    private let buildPath: Path?
    private let serialParse: Bool
    
    private let swiftGenerator: SwiftGenerator
    private let swiftParser: SwiftParser
    private let templateLoader: TemplateLoading

    public convenience init(
        watcherEnabled: Bool = false,
        cacheDisabled: Bool = false,
        buildPath: Path? = nil,
        serialParse: Bool = false
    ) {
        self.init(
            watcherEnabled: watcherEnabled,
            cacheDisabled: cacheDisabled,
            buildPath: buildPath,
            serialParse: serialParse,
            swiftGenerator: SwiftGenerator(),
            swiftParser: SwiftParser(),
            templateLoader: TemplateLoader()
        )
    }

    init(
        watcherEnabled: Bool = false,
        cacheDisabled: Bool = false,
        buildPath: Path? = nil,
        serialParse: Bool = false,
        swiftGenerator: SwiftGenerator,
        swiftParser: SwiftParser,
        templateLoader: TemplateLoading
    ) {
        self.watcherEnabled = watcherEnabled
        self.cacheDisabled = cacheDisabled
        self.buildPath = buildPath
        self.serialParse = serialParse
        self.swiftGenerator = swiftGenerator
        self.swiftParser = swiftParser
        self.templateLoader = templateLoader
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
        let templates = try templateLoader.loadTemplates(from: config, cacheDisabled: cacheDisabled, buildPath: buildPath)
        try swiftGenerator.generate(from: &parsingResult, using: templates, to: config.output, config: config)
        return parsingResult
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
            FSEventStream(path: path.string) { [templateLoader, cacheDisabled, buildPath] events in
                let events = events.filter { $0.flags.contains(.isFile) && Path($0.path).isTemplateFile }

                if events.isEmpty { return }

                do {
                    if events.count == 1 {
                        logger.info("Template changed \(events[0].path)")
                    } else {
                        logger.info("Templates changed: ")
                    }
                    let templates = try templateLoader.loadTemplates(from: config, cacheDisabled: cacheDisabled, buildPath: buildPath)
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
}
