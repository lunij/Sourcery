import Foundation
import PathKit
import SourceryRuntime

struct ConfigurationReader {
    let parser: ConfigurationParsing

    init(parser: ConfigurationParsing = ConfigurationParser()) {
        self.parser = parser
    }

    func readConfigurations(options: ConfigurationOptions) throws -> [Configuration] {
        try options.configPaths.flatMap { configPath -> [Configuration] in
            let configPath = configPath.isDirectory ? configPath + ".sourcery.yml" : configPath

            do {
                try configPath.checkConfigFile()

                if options.hasRedundantArguments { // TODO: do not ignore arguments, but override config setting
                    logger.info("Using configuration file at '\(configPath)'. WARNING: Ignoring the parameters passed in the command line.")
                } else {
                    logger.info("Using configuration file at '\(configPath)'")
                }

                return try parser.parseConfigurations(
                    from: configPath.read(),
                    relativePath: configPath.parent(),
                    env: ProcessInfo.processInfo.environment
                )
            } catch Error.configMissing {
                logger.info("No config file provided or it does not exist. Using command line arguments.")
                let args = options.args.joined(separator: ",")
                let arguments = AnnotationsParser.parse(line: args)
                return [
                    Configuration(
                        sources: .paths(Paths(include: options.sources, exclude: options.excludeSources)),
                        templates: Paths(include: options.templates, exclude: options.excludeTemplates),
                        output: Output(options.output),
                        cacheBasePath: options.cacheBasePath,
                        forceParse: options.forceParse,
                        parseDocumentation: options.parseDocumentation,
                        baseIndentation: options.baseIndentation,
                        arguments: arguments
                    )
                ]
            }
        }
    }

    enum Error: Swift.Error, Equatable {
        case configMissing
        case configNotAFile
        case configNotReadable
    }
}

private extension Path {
    func checkConfigFile() throws {
        guard exists else {
            throw ConfigurationReader.Error.configMissing
        }
        guard isFile else {
            throw ConfigurationReader.Error.configNotAFile
        }
        guard isReadable else {
            throw ConfigurationReader.Error.configNotReadable
        }
    }
}

private extension ConfigurationOptions {
    var hasRedundantArguments: Bool {
        !sources.isEmpty ||
            !excludeSources.isEmpty ||
            !templates.isEmpty ||
            !excludeTemplates.isEmpty ||
            !forceParse.isEmpty ||
            output != "" ||
            !args.isEmpty
    }
}
