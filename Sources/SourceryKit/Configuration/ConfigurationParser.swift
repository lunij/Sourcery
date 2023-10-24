import Foundation
import QuartzCore
import SourceryRuntime
import XcodeProj
import Yams

public protocol ConfigurationParsing {
    func parseConfigurations(from string: String, relativePath: Path, env: [String: String]) throws -> [Configuration]
    func parse(from string: String, relativePath: Path, env: [String: String]) throws -> Configuration
}

class ConfigurationParser: ConfigurationParsing {
    func parseConfigurations(
        from yaml: String,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws -> [Configuration] {
        guard let dict = try Yams.load(yaml: yaml, .default, Constructor(.customScalarMap(env: env))) as? [String: Any] else {
            throw ConfigurationParser.Error.invalidFormat(message: "Expected dictionary.")
        }

        let start = CFAbsoluteTimeGetCurrent()
        defer {
            logger.benchmark("Resolving configurations took \(CFAbsoluteTimeGetCurrent() - start)")
        }

        if let configurations = dict["configurations"] as? [[String: Any]] {
            return try configurations.map { dict in
                try parse(dict: dict, relativePath: relativePath)
            }
        } else {
            return try [parse(dict: dict, relativePath: relativePath)]
        }
    }

    func parse(
        from yaml: String,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws -> Configuration {
        guard let dict = try Yams.load(yaml: yaml, .default, Constructor(.customScalarMap(env: env))) as? [String: Any] else {
            throw Error.invalidFormat(message: "Expected dictionary.")
        }
        return try parse(dict: dict, relativePath: relativePath)
    }

    func parse(dict: [String: Any], relativePath: Path) throws -> Configuration {
        let sources = try Sources(dict: dict, relativePath: relativePath)
        guard !sources.isEmpty else {
            throw Error.invalidSources(message: "No sources provided.")
        }

        let templates: Paths
        guard let templatesDict = dict["templates"] else {
            throw Error.invalidTemplates(message: "'templates' key is missing.")
        }
        do {
            templates = try Paths(dict: templatesDict, relativePath: relativePath)
        } catch {
            throw Error.invalidTemplates(message: "\(error)")
        }
        guard !templates.isEmpty else {
            throw Error.invalidTemplates(message: "No templates provided.")
        }

        let output: Output = if let outputValue = dict["output"] as? String {
            Output(Path(outputValue, relativeTo: relativePath))
        } else if let output = dict["output"] as? [String: Any] {
            try Output(dict: output, relativePath: relativePath)
        } else {
            throw Error.invalidOutput(message: "'output' key is missing or is not a string or object.")
        }

        let cacheBasePath: Path = if let cacheBasePath = dict["cacheBasePath"] as? String {
            Path(cacheBasePath, relativeTo: relativePath)
        } else if dict["cacheBasePath"] != nil {
            throw Error.invalidCacheBasePath(message: "'cacheBasePath' key is not a string.")
        } else {
            .defaultBaseCachePath
        }

        return .init(
            sources: sources,
            templates: templates,
            output: output,
            cacheBasePath: cacheBasePath,
            forceParse: dict["forceParse"] as? [String] ?? [],
            parseDocumentation: dict["parseDocumentation"] as? Bool ?? false,
            baseIndentation: dict["baseIndentation"] as? Int ?? 0,
            arguments: dict["args"] as? [String: NSObject] ?? [:]
        )
    }

    enum Error: Swift.Error {
        case invalidFormat(message: String)
        case invalidSources(message: String)
        case invalidXCFramework(path: Path? = nil, message: String)
        case invalidTemplates(message: String)
        case invalidOutput(message: String)
        case invalidCacheBasePath(message: String)
        case invalidPaths(message: String)
    }
}

extension ConfigurationParser.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .invalidFormat(message):
            "Invalid config file format. \(message)"
        case let .invalidSources(message):
            "Invalid sources. \(message)"
        case let .invalidXCFramework(path, message):
            "Invalid xcframework\(path.map { " at path '\($0)'" } ?? "")'. \(message)"
        case let .invalidTemplates(message):
            "Invalid templates. \(message)"
        case let .invalidOutput(message):
            "Invalid output. \(message)"
        case let .invalidCacheBasePath(message):
            "Invalid cacheBasePath. \(message)"
        case let .invalidPaths(message):
            "\(message)"
        }
    }
}

private extension Constructor.ScalarMap {
    static func customScalarMap(env: [String: String]) -> Constructor.ScalarMap {
        var map = Constructor.defaultScalarMap
        map[.str] = String.constructExpandingEnvVars(env: env)
        return map
    }
}

private extension String {
    static func constructExpandingEnvVars(env: [String: String]) -> (_ scalar: Node.Scalar) -> String? {
        { scalar in
            scalar.string.expandingEnvVars(env: env)
        }
    }

    func expandingEnvVars(env: [String: String]) -> String? {
        // check if entry has an env variable
        guard let match = range(of: #"\$\{(.)\w+\}"#, options: .regularExpression) else {
            return self
        }

        // get the env variable as "${ENV_VAR}"
        let key = String(self[match])

        // get the env variable as "ENV_VAR" - note missing $ and brackets
        let keyString = String(key[2 ..< key.count - 1])

        guard let value = env[keyString] else { return "" }

        return replacingOccurrences(of: key, with: value)
    }
}

private extension StringProtocol {
    subscript(bounds: CountableClosedRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start ..< end]
    }

    subscript(bounds: CountableRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start ..< end]
    }
}

private extension Sources {
    init(dict: [String: Any], relativePath: Path) throws {
        if let projects = (dict["project"] as? [[String: Any]]) ?? (dict["project"] as? [String: Any]).map({ [$0] }) {
            guard !projects.isEmpty else { throw ConfigurationParser.Error.invalidSources(message: "No projects provided.") }
            self = try .projects(projects.map { try Project(dict: $0, relativePath: relativePath) })
        } else if let sources = dict["sources"] {
            do {
                self = try .paths(Paths(dict: sources, relativePath: relativePath))
            } catch {
                throw ConfigurationParser.Error.invalidSources(message: "\(error)")
            }
        } else {
            throw ConfigurationParser.Error.invalidSources(message: "'sources' or 'project' key are missing.")
        }
    }
}

private extension Paths {
    init(dict: Any, relativePath: Path) throws {
        if let sources = dict as? [String: [String]],
           let include = sources["include"]?.map({ Path($0, relativeTo: relativePath) })
        {
            let exclude = sources["exclude"]?.map { Path($0, relativeTo: relativePath) } ?? []
            self.init(include: include, exclude: exclude)
        } else if let sources = dict as? [String] {
            let sources = sources.map { Path($0, relativeTo: relativePath) }
            guard !sources.isEmpty else {
                throw ConfigurationParser.Error.invalidPaths(message: "No paths provided.")
            }
            self.init(include: sources)
        } else {
            throw ConfigurationParser.Error.invalidPaths(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
        }
    }
}

private extension Project {
    init(dict: [String: Any], relativePath: Path) throws {
        guard let file = dict["file"] as? String else {
            throw ConfigurationParser.Error.invalidSources(message: "Project file path is not provided. Expected string.")
        }

        let targetsArray: [Target]
        if let targets = dict["target"] as? [[String: Any]] {
            targetsArray = try targets.map { try Target(dict: $0, relativePath: relativePath) }
        } else if let target = dict["target"] as? [String: Any] {
            targetsArray = try [Target(dict: target, relativePath: relativePath)]
        } else {
            throw ConfigurationParser.Error.invalidSources(message: "'target' key is missing. Expected object or array of objects.")
        }
        if targetsArray.isEmpty {
            throw ConfigurationParser.Error.invalidSources(message: "No targets provided.")
        }
        targets = targetsArray

        let exclude = (dict["exclude"] as? [String])?.map { Path($0, relativeTo: relativePath) } ?? []
        self.exclude = exclude.flatMap(\.allPaths)

        let path = Path(file, relativeTo: relativePath)
        self.file = try XcodeProj(path: path)
        root = path.parent()
    }
}

private extension Project.Target {
    init(dict: [String: Any], relativePath: Path) throws {
        guard let name = dict["name"] as? String else {
            throw ConfigurationParser.Error.invalidSources(message: "Target name is not provided. Expected string.")
        }
        self.name = name
        module = (dict["module"] as? String) ?? name
        do {
            xcframeworks = try (dict["xcframeworks"] as? [String])?
                .map { try XCFramework(rawPath: $0, relativePath: relativePath) } ?? []
        } catch let error as ConfigurationParser.Error {
            logger.warning(error.description)
            self.xcframeworks = []
        }
    }
}

private extension Output {
    init(dict: [String: Any], relativePath: Path) throws {
        guard let path = dict["path"] as? String else {
            throw ConfigurationParser.Error.invalidOutput(message: "No path provided.")
        }

        self.path = Path(path, relativeTo: relativePath)

        if let linkToDict = dict["link"] as? [String: Any] {
            do {
                linkTo = try LinkTo(dict: linkToDict, relativePath: relativePath)
            } catch {
                linkTo = nil
                logger.warning(error)
            }
        } else {
            linkTo = nil
        }
    }
}

private extension Output.LinkTo {
    init(dict: [String: Any], relativePath: Path) throws {
        guard let project = dict["project"] as? String else {
            throw ConfigurationParser.Error.invalidOutput(message: "No project file path provided.")
        }
        if let target = dict["target"] as? String {
            targets = [target]
        } else if let targets = dict["targets"] as? [String] {
            self.targets = targets
        } else {
            throw ConfigurationParser.Error.invalidOutput(message: "No target(s) provided.")
        }
        let projectPath = Path(project, relativeTo: relativePath)
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        group = dict["group"] as? String
    }
}
