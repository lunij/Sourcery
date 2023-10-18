import Foundation
import PathKit
import SourceryRuntime

struct ConfigurationReader {
    func readConfigurations(options: ConfigurationOptions) throws -> [Configuration] {
        try options.configPaths.flatMap { configPath -> [Configuration] in
            let configPath = configPath.isDirectory ? configPath + ".sourcery.yml" : configPath

            do {
                try configPath.checkConfigFile()

                let hasAnyYamlDuplicatedParameter = (
                    !options.sources.isEmpty ||
                    !options.excludeSources.isEmpty ||
                    !options.templates.isEmpty ||
                    !options.excludeTemplates.isEmpty ||
                    !options.forceParse.isEmpty ||
                    options.output != "" ||
                    !options.args.isEmpty
                )

                if hasAnyYamlDuplicatedParameter {
                    logger.info("Using configuration file at '\(configPath)'. WARNING: Ignoring the parameters passed in the command line.")
                } else {
                    logger.info("Using configuration file at '\(configPath)'")
                }

                return try Configurations.make(
                    path: configPath,
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
                        args: arguments
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
