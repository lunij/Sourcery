import Foundation
import QuartzCore
import PathKit
import SourceryRuntime
import XcodeProj
import Yams

public protocol ConfigurationParsing {
    func parse(from string: String, basePath: Path, env: [String: String]) throws -> [Configuration]
}

class ConfigurationParser: ConfigurationParsing {
    func parse(
        from yaml: String,
        basePath: Path,
        env: [String: String]
    ) throws -> [Configuration] {
        guard let dict = try Yams.load(yaml: yaml, .default, Constructor(.customScalarMap(env: env))) as? [String: Any] else {
            throw Error.invalidFormat(message: "Expected dictionary.")
        }

        if let configurations = dict["configurations"] as? [[String: Any]] {
            return try configurations.map { dict in
                try parse(dict: dict, basePath: basePath)
            }
        } else {
            return try [parse(dict: dict, basePath: basePath)]
        }
    }

    private func parse(dict: [String: Any], basePath: Path) throws -> Configuration {
        let sources = try Sources(dict: dict, basePath: basePath)
        guard !sources.isEmpty else {
            throw Error.invalidSources(message: "No sources provided.")
        }

        let templates = try parseTemplatePaths(from: dict, basePath: basePath)

        let output: Output = if let value = dict["output"] {
            try Output(value: value, basePath: basePath)
        } else {
            throw Error.invalidOutput(message: "'output' key is missing.")
        }

        let cacheBasePath: Path = if let cacheBasePath = dict["cacheBasePath"] as? String {
            Path(cacheBasePath, relativeTo: basePath)
        } else if dict["cacheBasePath"] != nil {
            throw Error.invalidCacheBasePath(message: "'cacheBasePath' key is not a string.")
        } else {
            .systemCachePath
        }

        let cacheDisabled = if let cacheDisabled = dict["cacheDisabled"] as? Bool {
            cacheDisabled
        } else if dict["cacheDisabled"] != nil {
            throw Error.invalidCacheDisabled(message: "Expected a boolean.")
        } else {
            false
        }

        return .init(
            sources: sources,
            templates: templates,
            output: output,
            cacheBasePath: cacheBasePath,
            cacheDisabled: cacheDisabled,
            forceParse: dict["forceParse"] as? [String] ?? [],
            parseDocumentation: dict["parseDocumentation"] as? Bool ?? false,
            baseIndentation: dict["baseIndentation"] as? Int ?? 0,
            arguments: dict["args"] as? [String: NSObject] ?? [:]
        )
    }

    private func parseTemplatePaths(from dict: [String: Any], basePath: Path) throws -> Paths {
        guard let value = dict["templates"] else {
            throw Error.invalidTemplates(message: "'templates' key is missing.")
        }
        do {
            return try Paths(from: value, basePath: basePath)
        } catch {
            throw Error.invalidTemplates(message: "\(error)")
        }
    }

    enum Error: Swift.Error, Equatable {
        case invalidFormat(message: String)
        case invalidProject(message: String)
        case invalidSources(message: String)
        case invalidTarget(message: String)
        case invalidXCFramework(path: Path? = nil, message: String)
        case invalidTemplates(message: String)
        case invalidOutput(message: String)
        case invalidCacheBasePath(message: String)
        case invalidCacheDisabled(message: String)
        case invalidPaths(message: String)
    }
}

extension ConfigurationParser.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .invalidFormat(message):
            "Invalid config file format. \(message)"
        case let .invalidProject(message):
            "Invalid project. \(message)"
        case let .invalidSources(message):
            "Invalid sources. \(message)"
        case let .invalidTarget(message):
            "Invalid target. \(message)"
        case let .invalidXCFramework(path, message):
            "Invalid xcframework\(path.map { " at path '\($0)'" } ?? "")'. \(message)"
        case let .invalidTemplates(message):
            "Invalid templates. \(message)"
        case let .invalidOutput(message):
            "Invalid output. \(message)"
        case let .invalidCacheBasePath(message):
            "Invalid cacheBasePath. \(message)"
        case let .invalidCacheDisabled(message):
            "Invalid cacheDisabled. Expected a boolean, but got a \(message)."
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
    init(dict: [String: Any], basePath: Path) throws {
        if let project = dict["project"] {
            if let dict = project as? [String: Any] {
                self = try .projects([Project(dict: dict, basePath: basePath)])
            } else {
                throw ConfigurationParser.Error.invalidProject(message: "Expected an object.")
            }
        } else if let sources = dict["sources"] {
            do {
                self = try .paths(Paths(from: sources, basePath: basePath))
            } catch {
                throw ConfigurationParser.Error.invalidSources(message: "\(error)")
            }
        } else {
            throw ConfigurationParser.Error.invalidSources(message: "'sources' or 'project' key are missing.")
        }
    }
}

private extension Paths {
    init(from value: Any, basePath: Path) throws {
        if let sources = value as? [String: [String]],
           let include = sources["include"]?.map({ Path($0, relativeTo: basePath) })
        {
            let exclude = sources["exclude"]?.map { Path($0, relativeTo: basePath) } ?? []
            self.init(include: include, exclude: exclude)
        } else if let sources = value as? [String] {
            let sources = sources.map { Path($0, relativeTo: basePath) }
            guard !sources.isEmpty else {
                throw ConfigurationParser.Error.invalidPaths(message: "No paths provided.")
            }
            self.init(include: sources)
        } else if let source = value as? String {
            let sourcePath = Path(source, relativeTo: basePath)
            self.init(include: [sourcePath])
        } else {
            throw ConfigurationParser.Error.invalidPaths(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
        }
    }
}

private extension Project {
    init(dict: [String: Any], basePath: Path) throws {
        guard let file = dict["file"] as? String else {
            throw ConfigurationParser.Error.invalidProject(message: "Project file path is not provided. Expected string.")
        }

        let targetsArray: [Target]
        if let targets = dict["target"] as? [[String: Any]] {
            targetsArray = try targets.map { try Target(dict: $0, basePath: basePath) }
        } else if let target = dict["target"] as? [String: Any] {
            targetsArray = try [Target(dict: target, basePath: basePath)]
        } else if dict["target"] != nil {
            throw ConfigurationParser.Error.invalidTarget(message: "Expected an object or an array of objects.")
        } else {
            throw ConfigurationParser.Error.invalidProject(message: "'target' key is missing.")
        }
        if targetsArray.isEmpty {
            throw ConfigurationParser.Error.invalidProject(message: "No targets provided.")
        }
        targets = targetsArray

        let exclude = (dict["exclude"] as? [String])?.map { Path($0, relativeTo: basePath) } ?? []
        self.exclude = exclude.flatMap(\.allPaths)

        path = Path(file, relativeTo: basePath)
    }
}

private extension Project.Target {
    init(dict: [String: Any], basePath: Path) throws {
        guard let name = dict["name"] as? String else {
            throw ConfigurationParser.Error.invalidTarget(message: "Target name is not provided. Expected a string.")
        }
        self.name = name
        module = (dict["module"] as? String) ?? name
        do {
            xcframeworks = try (dict["xcframeworks"] as? [String])?
                .map { try XCFramework(rawPath: $0, basePath: basePath) } ?? []
        } catch let error as ConfigurationParser.Error {
            logger.warning(error.description)
            self.xcframeworks = []
        }
    }
}

private extension Project.Target.XCFramework {
    init(rawPath: String, basePath: Path) throws {
        let path = Path(rawPath, relativeTo: basePath)

        guard let framework = path.components.last else {
            throw ConfigurationParser.Error.invalidXCFramework(message: "Framework path invalid. Expected String.")
        }

        guard Path(framework).extension == "xcframework" else {
            throw ConfigurationParser.Error.invalidXCFramework(message: "Framework path invalid. Expected path to xcframework file.")
        }

        guard let simulatorSlicePath = path.glob("*").first(where: { $0.lastComponent.contains("simulator") }) else {
            throw ConfigurationParser.Error.invalidXCFramework(path: path, message: "Framework path invalid. Expected to find simulator slice.")
        }
        
        let moduleName = Path(framework).lastComponentWithoutExtension
        let modulePath = simulatorSlicePath + Path("\(moduleName).framework/Modules/\(moduleName).swiftmodule/")
        guard let swiftInterfacePath = modulePath.glob("*.swiftinterface").first(where: { $0.lastComponent.contains("simulator") }) else {
            throw ConfigurationParser.Error.invalidXCFramework(path: path, message: "Framework path invalid. Expected to find .swiftinterface.")
        }

        self.path = path
        self.swiftInterfacePath = swiftInterfacePath
    }
}

private extension Output {
    init(value: Any, basePath: Path) throws {
        if let path = value as? String {
            self.path = Path(path, relativeTo: basePath)
            self.link = nil
            return
        }

        guard let outputDict = value as? [String: Any] else {
            throw ConfigurationParser.Error.invalidOutput(message: "Expected an object or a string.")
        }

        guard let path = outputDict["path"] as? String else {
            throw ConfigurationParser.Error.invalidOutput(message: "Output path not provided. Expected a string.")
        }

        self.path = Path(path, relativeTo: basePath)

        if let linkDict = outputDict["link"] as? [String: Any] {
            do {
                link = try LinkTo(dict: linkDict, basePath: basePath)
            } catch {
                link = nil
                logger.warning(error)
            }
        } else {
            link = nil
        }
    }
}

private extension Output.LinkTo {
    init(dict: [String: Any], basePath: Path) throws {
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
        let projectPath = Path(project, relativeTo: basePath)
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        group = dict["group"] as? String
    }
}
