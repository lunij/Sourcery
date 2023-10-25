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

    @Flag(name: .shortAndLong, help: "Turn on verbose logging")
    var verbose = false

    @Flag(help: "Log AST messages")
    var logAST = false

    @Flag(help: "Log time benchmark info")
    var logBenchmark = false

    @Flag(name: .shortAndLong, help: "Turn off any logging, only emmit errors")
    var quiet = false

    @Option(help: "Set a custom build path")
    var buildPath: Path = ""

    public init() {}

    public func run() async throws {
        if quiet, verbose {
            throw Error.quietVerboseIncompatibility
        }

        logger = Logger(
            level: quiet ? .error : verbose ? .verbose : .info,
            logAST: (logAST || verbose) && !quiet,
            logBenchmarks: (logBenchmark || verbose) && !quiet
        )

        let start = CFAbsoluteTimeGetCurrent()

        let configReader = ConfigurationReader()

        for configuration in try configReader.readConfigurations(options: options) {
            try processFiles(specifiedIn: configuration)
        }

        logger.info("Processing time \(CFAbsoluteTimeGetCurrent() - start) seconds")
    }

    private func processFiles(specifiedIn configuration: Configuration) throws {
        try configuration.validate()

        let sourcery = Sourcery(
            watcherEnabled: watcherEnabled,
            buildPath: buildPath.string.isEmpty ? nil : buildPath
        )

        try sourcery.processConfiguration(configuration)
    }

    enum Error: Swift.Error, Equatable {
        case quietVerboseIncompatibility
    }
}

extension SourceryCommand.Error: CustomStringConvertible {
    public var description: String {
        switch self {
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
