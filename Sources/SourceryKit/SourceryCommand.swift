import ArgumentParser
import FileSystemEvents
import Foundation
import PathKit
import SourceryRuntime

public struct SourceryCommand: AsyncParsableCommand {
    public static var configuration = CommandConfiguration(
        commandName: "sourcery",
        abstract: "A Swift code generator",
        version: Sourcery.version
    )

    @OptionGroup
    var options: ConfigurationOptions

    @Flag(name: [.customLong("watch"), .short], help: "Watch template for changes and regenerate as needed")
    var watcherEnabled = false

    @Flag(name: [.customLong("no-cache")], help: "Stop using cache")
    var cacheDisabled = false

    @Flag(name: .shortAndLong, help: "Turn on verbose logging")
    var verbose = false

    @Flag(help: "Log AST messages")
    var logAST = false

    @Flag(help: "Log time benchmark info")
    var logBenchmark = false

    @Flag(name: .shortAndLong, help: "Turn off any logging, only emmit errors")
    var quiet = false

    @Flag(name: .shortAndLong, help: "Remove empty generated files")
    var prune = false

    @Flag(help: "Parse the specified sources in serial, rather than in parallel (the default), which can address stability issues in SwiftSyntax")
    var serialParse = false

    @Flag(name: .customLong("dry"), help: "Dry run, without file system modifications, will output result and errors in JSON format")
    var isDryRun = false

    @Option(help: "Set a custom build path")
    var buildPath: Path = ""

    public init() {}

    public func run() async throws {
        if isDryRun, watcherEnabled {
            throw Error.dryWatchIncompatibility
        }

        if quiet, verbose {
            throw Error.quietVerboseIncompatibility
        }

        logger = Logger(
            level: quiet ? .error : verbose ? .verbose : .info,
            logAST: (logAST || verbose) && !quiet,
            logBenchmarks: (logBenchmark || verbose) && !quiet,
            stackMessages: isDryRun
        )

        do {
            let start = CFAbsoluteTimeGetCurrent()

            let configReader = ConfigurationReader()

            for configuration in try configReader.readConfigurations(options: options) {
                try processFiles(specifiedIn: configuration)
            }

            logger.info("Processing time \(CFAbsoluteTimeGetCurrent() - start) seconds")
        } catch {
            if isDryRun {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try? encoder.encode(DryOutputFailure(error: "\(error)", log: logger.messages))
                data.flatMap { logger.output(String(data: $0, encoding: .utf8) ?? "") }
            } else {
                throw error
            }
        }
    }

    private func processFiles(specifiedIn configuration: Configuration) throws {
        try configuration.validate()

        let shouldUseCacheBasePathArg = configuration.cacheBasePath == Path.defaultBaseCachePath && !options.cacheBasePath.string.isEmpty

        let sourcery = Sourcery(
            verbose: verbose,
            watcherEnabled: watcherEnabled,
            cacheDisabled: cacheDisabled,
            cacheBasePath: shouldUseCacheBasePathArg ? options.cacheBasePath : configuration.cacheBasePath,
            buildPath: buildPath.string.isEmpty ? nil : buildPath,
            prune: prune,
            serialParse: serialParse,
            arguments: configuration.args
        )

        try sourcery.processSources(
            configuration.sources,
            usingTemplates: configuration.templates,
            output: configuration.output,
            isDryRun: isDryRun,
            forceParse: configuration.forceParse,
            parseDocumentation: configuration.parseDocumentation,
            baseIndentation: configuration.baseIndentation
        )
    }

    enum Error: Swift.Error, Equatable {
        case dryWatchIncompatibility
        case quietVerboseIncompatibility
    }
}

extension SourceryCommand.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dryWatchIncompatibility:
            "--dry not compatible with --watch"
        case .quietVerboseIncompatibility:
            "--quiet not compatible with --verbose"
        }
    }
}

extension Path: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
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
    func validate() throws {
        try validateSources()
        try validateTemplates()
        try validateOutput()
    }

    private func validateSources() throws {
        if sources.isEmpty {
            throw ConfigurationValidationError.missingSources
        }
        if case let .paths(paths) = sources {
            for path in paths.allPaths {
                try path.validateReadability()
            }
        }
    }

    private func validateTemplates() throws {
        if templates.isEmpty {
            throw ConfigurationValidationError.missingTemplates
        }
        for path in templates.allPaths {
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
