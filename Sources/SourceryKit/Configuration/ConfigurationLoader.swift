import Foundation
import PathKit
import SourceryRuntime

protocol ConfigurationLoading {
    func loadConfigurations(options: ConfigurationOptions) throws -> [Configuration]
}

struct ConfigurationLoader: ConfigurationLoading {
    private let parser: ConfigurationParsing
    private let pathResolver: PathResolving
    private let fileReader: FileReading
    private let environment: [String: String]

    init(
        parser: ConfigurationParsing = ConfigurationParser(),
        pathResolver: PathResolving = PathResolver(),
        fileReader: FileReading = FileReader(),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.parser = parser
        self.pathResolver = pathResolver
        self.fileReader = fileReader
        self.environment = environment
    }

    func loadConfigurations(options: ConfigurationOptions) throws -> [Configuration] {
        let configs: [Configuration] = try options.configPaths.flatMap { configPath in
            do {
                let configPath = configPath.isDirectory || configPath.isRepresentingDirectory ? configPath + ".sourcery.yml" : configPath
                let configString = try fileReader.read(from: configPath)

                logger.info("Loading configuration file at \(configPath)")

                return try parser.parse(
                    from: configString,
                    basePath: configPath.parent(),
                    env: environment
                )
            } catch let FileReader.Error.fileNotExisting(path) where path == ".sourcery.yml" {
                return []
            }
        }

        if configs.isEmpty {
            logger.info("No configuration files loaded. Using default configuration and command line arguments.")
            let args = options.args.joined(separator: ",")
            let arguments = AnnotationsParser.parse(line: args)
            return [
                Configuration(
                    sources: pathResolver.resolveSources(from: options),
                    templates: pathResolver.resolveTemplates(from: options),
                    output: options.output,
                    xcode: nil,
                    cacheBasePath: options.cacheBasePath,
                    cacheDisabled: options.cacheDisabled,
                    forceParse: options.forceParse,
                    parseDocumentation: options.parseDocumentation,
                    baseIndentation: options.baseIndentation,
                    arguments: arguments
                )
            ]
        }

        return configs
    }
}

private extension PathResolving {
    func resolveSources(from options: ConfigurationOptions) -> [SourceFile] {
        resolve(includes: options.sources, excludes: options.excludeSources)
            .map { SourceFile(path: $0, module: nil) }
    }

    func resolveTemplates(from options: ConfigurationOptions) -> [Path] {
        resolve(includes: options.templates, excludes: options.excludeTemplates)
    }
}
