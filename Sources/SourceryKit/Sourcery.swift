import FileSystemEvents
import SourceryRuntime

public class Sourcery {
    public static let version = "2.0.2"

    private let watcherEnabled: Bool
    private let buildPath: Path?
    
    private let clock: TimeMeasuring
    private let configLoader: ConfigurationLoading
    private let swiftGenerator: SwiftGenerator
    private let swiftParser: SwiftParser
    private let templateLoader: TemplateLoading

    public convenience init(
        watcherEnabled: Bool = false,
        buildPath: Path? = nil
    ) {
        self.init(
            watcherEnabled: watcherEnabled,
            buildPath: buildPath,
            clock: ContinuousClock(),
            configLoader: ConfigurationLoader(),
            swiftGenerator: SwiftGenerator(),
            swiftParser: SwiftParser(),
            templateLoader: TemplateLoader()
        )
    }

    init(
        watcherEnabled: Bool = false,
        buildPath: Path? = nil,
        clock: TimeMeasuring,
        configLoader: ConfigurationLoading,
        swiftGenerator: SwiftGenerator,
        swiftParser: SwiftParser,
        templateLoader: TemplateLoading
    ) {
        self.watcherEnabled = watcherEnabled
        self.buildPath = buildPath
        self.clock = clock
        self.configLoader = configLoader
        self.swiftGenerator = swiftGenerator
        self.swiftParser = swiftParser
        self.templateLoader = templateLoader
    }

    func process(using options: ConfigurationOptions) throws {
        let elapsedTime = try clock.measure {
            for configuration in try configLoader.loadConfigurations(options: options) {
                try processConfiguration(configuration)
            }
        }
        logger.info("Processing finished in \(elapsedTime)")
    }

    @discardableResult
    func processConfiguration(_ config: Configuration) throws -> [FSEventStream] {
        try config.validate()
        let parserResult = try process(config)
        return watcherEnabled ? createWatchers(config: config, parserResult: parserResult) : []
    }

    private func process(_ config: Configuration) throws -> ParsingResult {
        var parsingResult = try swiftParser.parseSources(from: config)
        let templates = try templateLoader.loadTemplates(from: config, buildPath: buildPath)
        try swiftGenerator.generate(from: &parsingResult, using: templates, to: config.output, config: config)
        return parsingResult
    }

    private func createWatchers(config: Configuration, parserResult: ParsingResult) -> [FSEventStream] {
        var result = parserResult

        logger.info("Starting watching sources.")

        let sourceWatchers = topPaths(from: config.sources.map(\.path)).compactMap { path in
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
                        result = try self.process(config)
                    } catch {
                        logger.error(error)
                    }
                }
            }
        }

        logger.info("Starting watching templates.")

        let templateWatchers = topPaths(from: config.templates).compactMap { path in
            FSEventStream(path: path.string) { [templateLoader, buildPath] events in
                let events = events.filter { $0.flags.contains(.isFile) && Path($0.path).isTemplateFile }

                if events.isEmpty { return }

                do {
                    if events.count == 1 {
                        logger.info("Template changed \(events[0].path)")
                    } else {
                        logger.info("Templates changed: ")
                    }
                    let templates = try templateLoader.loadTemplates(from: config, buildPath: buildPath)
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

enum ConfigurationValidationError: Error, Equatable {
    case fileNotReadable(Path)
    case missingSources
    case missingTemplates
    case outputNotWritable(Path)
}

extension ConfigurationValidationError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .fileNotReadable(path):
            "'\(path)' does not exist or is not readable."
        case .missingSources:
            "No sources provided."
        case .missingTemplates:
            "No templates provided."
        case let .outputNotWritable(path):
            "'\(path)' isn't writable."
        }
    }
}

private extension Configuration {
    func validate() throws { // TODO: move to ConfigurationLoader or introduce ConfigurationValidator
        try validateSources()
        try validateTemplates()
        try validateOutput()
    }

    private func validateSources() throws {
        if sources.isEmpty {
            throw ConfigurationValidationError.missingSources
        }
        for sourceFile in sources {
            try sourceFile.path.validateReadability()
        }
    }

    private func validateTemplates() throws {
        if templates.isEmpty {
            throw ConfigurationValidationError.missingTemplates
        }
        for path in templates {
            try path.validateReadability()
        }
    }

    private func validateOutput() throws {
        try output.path.validateWritablity()
    }
}

private extension Path {
    func validateReadability() throws {
        if isReadable { return }
        throw ConfigurationValidationError.fileNotReadable(self)
    }

    func validateWritablity() throws {
        if exists && !isWritable {
            throw ConfigurationValidationError.outputNotWritable(self)
        }
    }
}
