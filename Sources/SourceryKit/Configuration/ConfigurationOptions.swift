import ArgumentParser

struct ConfigurationOptions: ParsableArguments {
    @Option(name: .customLong("config"), help: "Path to config file. File or Directory. Default is current path")
    var configPaths: [Path] = ["."]

    @Option(help: "Path to one or more Swift files or directories containing such")
    var sources: [Path] = []

    @Option(help: "Path to one or more Swift files or directories containing such to exclude them")
    var excludeSources: [Path] = []

    @Option(help: "Path to templates")
    var templates: [Path] = []

    @Option(help: "Path to templates to exclude them")
    var excludeTemplates: [Path] = []

    @Option(help: "Path to output. File or Directory. Default is current path")
    var output: Path = "."

    @Option(help: "File extensions that will be forced to parse, even if they were generated")
    var forceParse: [String] = []

    @Option(help: """
    Additional arguments to pass to templates. Each argument can have an explicit value or will have \
    an implicit `true` value. Arguments should be comma-separated without spaces (e.g. --args arg1=value,arg2) \
    or should be passed one by one (e.g. --args arg1=value --args arg2). Arguments are accessible in templates \
    via `argument.<name>`. To pass in string you should use escaped quotes (\\").
    """)
    var args: [String] = []

    @Option(help: "Base path to Sourcery's cache directory")
    var cacheBasePath: Path = .systemCachePath

    @Flag(help: "Include documentation comments for all declarations")
    var parseDocumentation = false

    @Flag(name: [.customLong("no-cache")], help: "Stop using cache")
    var cacheDisabled = false
}
