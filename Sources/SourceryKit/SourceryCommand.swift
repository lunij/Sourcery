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
        do {
            setupLogger(isDryRun, quiet, verbose, logBenchmark, logAST)

            let start = CFAbsoluteTimeGetCurrent()

            let configReader = ConfigurationReader()

            for configuration in try configReader.readConfigurations(options: options) {
                try processFiles(specifiedIn: configuration)
            }

            Log.info("Processing time \(CFAbsoluteTimeGetCurrent() - start) seconds")
        } catch {
            if isDryRun {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try? encoder.encode(DryOutputFailure(error: "\(error)", log: Log.messagesStack))
                data.flatMap { Log.output(String(data: $0, encoding: .utf8) ?? "") }
            } else {
                Log.error("\(error)")
            }
            exitSourcery(.other)
        }
    }

    private func processFiles(specifiedIn configuration: Configuration) throws {
        configuration.validate()

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

        if isDryRun, watcherEnabled {
            throw "--dry not compatible with --watch"
        }

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
}

extension Path: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}

enum ExitCode: Int32 {
    case invalidPath = 1
    case invalidConfig
    case other
}

func exitSourcery(_ code: ExitCode) -> Never {
    exit(code.rawValue)
}

enum Validators {
    static func isReadable(path: Path) -> Path {
        if !path.isReadable {
            Log.error("'\(path)' does not exist or is not readable.")
            exitSourcery(.invalidPath)
        }

        return path
    }

    static func isWritable(path: Path) -> Path {
        if path.exists && !path.isWritable {
            Log.error("'\(path)' isn't writable.")
            exitSourcery(.invalidPath)
        }
        return path
    }
}

extension Configuration {
    func validate() {
        guard !sources.isEmpty else {
            Log.error("No sources provided.")
            exitSourcery(.invalidConfig)
        }
        if case let .paths(paths) = sources {
            _ = paths.allPaths.map(Validators.isReadable(path:))
        }

        guard !templates.isEmpty else {
            Log.error("No templates provided.")
            exitSourcery(.invalidConfig)
        }
        _ = templates.allPaths.map(Validators.isReadable(path:))
        _ = output.path.map(Validators.isWritable(path:))
    }
}

private func setupLogger(
    _ isDryRun: Bool,
    _ quiet: Bool,
    _ verbose: Bool,
    _ logBenchmark: Bool,
    _ logAST: Bool
) {
    Log.stackMessages = isDryRun

    if quiet {
        Log.level = .errors
    } else {
        Log.level = verbose ? .verbose : .info
    }

    Log.logBenchmarks = (verbose || logBenchmark) && !quiet
    Log.logAST = (verbose || logAST) && !quiet
}
