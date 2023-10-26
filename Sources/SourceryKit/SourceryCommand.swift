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

        let sourcery = Sourcery(
            watcherEnabled: watcherEnabled,
            buildPath: buildPath.string.isEmpty ? nil : buildPath
        )

        try sourcery.process(using: options)
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
