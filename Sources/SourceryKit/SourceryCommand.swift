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

    @Flag(help: "Include documentation comments for all declarations")
    var parseDocumentation = false

    @Flag(name: .shortAndLong, help: "Turn off any logging, only emmit errors")
    var quiet = false

    @Flag(name: .shortAndLong, help: "Remove empty generated files")
    var prune = false

    @Flag(help: "Parse the specified sources in serial, rather than in parallel (the default), which can address stability issues in SwiftSyntax")
    var serialParse = false

    @Option(help: "Path to one or more Swift files or directories containing such")
    var sources: [Path] = []

    @Option(help: "Path to one or more Swift files or directories containing such to exclude them")
    var excludeSources: [Path] = []

    @Option(help: "Path to templates")
    var templates: [Path] = []

    @Option(help: "Path to templates to exclude them")
    var excludeTemplates: [Path] = []

    @Option(help: "Path to output. File or Directory. Default is current path")
    var output: Path = ""

    @Flag(name: .customLong("dry"), help: "Dry run, without file system modifications, will output result and errors in JSON format")
    var isDryRun = false

    @Option(name: .customLong("config"), help: "Path to config file. File or Directory. Default is current path")
    var configPaths: [Path] = ["."]

    @Option(help: "File extensions that will be forced to parse, even if they were generated")
    var forceParse: [String] = []

    @Option(help: "Base indendation to add to sourcery:auto fragments")
    var baseIndentation = 0

    @Option(help: """
        Additional arguments to pass to templates. Each argument can have an explicit value or will have \
        an implicit `true` value. Arguments should be comma-separated without spaces (e.g. --args arg1=value,arg2) \
        or should be passed one by one (e.g. --args arg1=value --args arg2). Arguments are accessible in templates \
        via `argument.<name>`. To pass in string you should use escaped quotes (\\").
        """)
    var args: [String] = []

    @Option(help: "Base path to Sourcery's cache directory")
    var cacheBasePath: Path = ""

    @Option(help: "Set a custom build path")
    var buildPath: Path = ""

    public init() {}

    public func run() async throws {
        do {
            Log.stackMessages = isDryRun
            switch (quiet, verbose) {
            case (true, _):
                Log.level = .errors
            case (false, let isVerbose):
                Log.level = isVerbose ? .verbose : .info
            }
            Log.logBenchmarks = (verbose || logBenchmark) && !quiet
            Log.logAST = (verbose || logAST) && !quiet

            let configurations = readConfigurations()

            let start = CFAbsoluteTimeGetCurrent()

            try processFiles(specifiedIn: configurations)

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

    private func readConfigurations() -> [Configuration] {
        configPaths.flatMap { configPath -> [Configuration] in
            let yamlPath = configPath.isDirectory ? configPath + ".sourcery.yml" : configPath

            if !yamlPath.exists {
                Log.info("No config file provided or it does not exist. Using command line arguments.")
                let args = args.joined(separator: ",")
                let arguments = AnnotationsParser.parse(line: args)
                return [
                    Configuration(
                        sources: Paths(include: sources, exclude: excludeSources) ,
                        templates: Paths(include: templates, exclude: excludeTemplates),
                        output: output.string.isEmpty ? "." : output,
                        cacheBasePath: cacheBasePath.string.isEmpty ? Path.defaultBaseCachePath : cacheBasePath,
                        forceParse: forceParse,
                        parseDocumentation: parseDocumentation,
                        baseIndentation: baseIndentation,
                        args: arguments
                    )
                ]
            } else {
                _ = Validators.isFileOrDirectory(path: configPath)
                _ = Validators.isReadable(path: yamlPath)

                do {
                    let relativePath: Path = configPath.isDirectory ? configPath : configPath.parent()

                    // Check if the user is passing parameters
                    // that are ignored cause read from the yaml file
                    let hasAnyYamlDuplicatedParameter = (
                        !sources.isEmpty ||
                            !excludeSources.isEmpty ||
                            !templates.isEmpty ||
                            !excludeTemplates.isEmpty ||
                            !forceParse.isEmpty ||
                            output != "" ||
                            !args.isEmpty
                    )

                    if hasAnyYamlDuplicatedParameter {
                        Log.info("Using configuration file at '\(yamlPath)'. WARNING: Ignoring the parameters passed in the command line.")
                    } else {
                        Log.info("Using configuration file at '\(yamlPath)'")
                    }

                    return try Configurations.make(
                        path: yamlPath,
                        relativePath: relativePath,
                        env: ProcessInfo.processInfo.environment
                    )
                } catch {
                    Log.error("while reading .yml '\(yamlPath)'. '\(error)'")
                    exitSourcery(.invalidConfig)
                }
            }
        }
    }

    private func processFiles(specifiedIn configurations: [Configuration]) throws {
        for configuration in configurations {
            configuration.validate()

            let shouldUseCacheBasePathArg = configuration.cacheBasePath == Path.defaultBaseCachePath && !cacheBasePath.string.isEmpty

            let sourcery = Sourcery(
                verbose: verbose,
                watcherEnabled: watcherEnabled,
                cacheDisabled: cacheDisabled,
                cacheBasePath: shouldUseCacheBasePathArg ? cacheBasePath : configuration.cacheBasePath,
                buildPath: buildPath.string.isEmpty ? nil : buildPath,
                prune: prune,
                serialParse: serialParse,
                arguments: configuration.args
            )

            if isDryRun, watcherEnabled {
                throw "--dry not compatible with --watch"
            }

            try sourcery.processFiles(
                configuration.source,
                usingTemplates: configuration.templates,
                output: configuration.output,
                isDryRun: isDryRun,
                forceParse: configuration.forceParse,
                parseDocumentation: configuration.parseDocumentation,
                baseIndentation: configuration.baseIndentation
            )
        }
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

private func exitSourcery(_ code: ExitCode) -> Never {
    exit(code.rawValue)
}

private enum Validators {
    static func isReadable(path: Path) -> Path {
        if !path.isReadable {
            Log.error("'\(path)' does not exist or is not readable.")
            exitSourcery(.invalidPath)
        }

        return path
    }

    static func isFileOrDirectory(path: Path) -> Path {
        _ = isReadable(path: path)

        if !(path.isDirectory || path.isFile) {
            Log.error("'\(path)' isn't a directory or proper file.")
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
        guard !source.isEmpty else {
            Log.error("No sources provided.")
            exitSourcery(.invalidConfig)
        }
        if case let .sources(sources) = source {
            _ = sources.allPaths.map(Validators.isReadable(path:))
        }

        guard !templates.isEmpty else {
            Log.error("No templates provided.")
            exitSourcery(.invalidConfig)
        }
        _ = templates.allPaths.map(Validators.isReadable(path:))
        _ = output.path.map(Validators.isWritable(path:))
    }
}
