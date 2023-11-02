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
    private let pathResolver: PathResolving
    private let xcodeProjFactory: XcodeProjFactoryProtocol

    init(
        pathResolver: PathResolving = PathResolver(),
        xcodeProjFactory: XcodeProjFactoryProtocol = XcodeProjFactory()
    ) {
        self.pathResolver = pathResolver
        self.xcodeProjFactory = xcodeProjFactory
    }

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
        let sourcePaths = try parseSourcePaths(from: dict, basePath: basePath)
        let templatePaths = try parseTemplatePaths(from: dict, basePath: basePath)
        let projectSourcePaths = try parseProjectSourcePaths(from: dict, basePath: basePath)

        guard let sourcePaths = sourcePaths ?? projectSourcePaths else {
            throw Error.invalidSources(message: "Expected either 'sources' key or 'project' key.")
        }

        let output = try parseOutput(from: dict, basePath: basePath)
        let xcode = try parseXcode(from: dict, basePath: basePath)

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
            sources: sourcePaths,
            templates: templatePaths,
            output: output,
            xcode: xcode,
            cacheBasePath: cacheBasePath,
            cacheDisabled: cacheDisabled,
            forceParse: dict["forceParse"] as? [String] ?? [],
            parseDocumentation: dict["parseDocumentation"] as? Bool ?? false,
            arguments: dict["args"] as? [String: NSObject] ?? [:]
        )
    }

    private func parseOutput(from dict: [String: Any], basePath: Path) throws -> Path {
        guard let value = dict["output"] else {
            throw Error.invalidOutput(message: "'output' key is missing.")
        }

        guard let output = value as? String else {
            throw Error.invalidOutput(message: "'output' key is not a string.")
        }

        return basePath + output
    }

    private func parseXcode(from dict: [String: Any], basePath: Path) throws -> Xcode? {
        guard let value = dict["xcode"] else {
            return nil
        }

        guard let dict = value as? [String: Any] else {
            throw Error.invalidXcode(message: "Expected an object.")
        }

        guard let project = dict["project"] as? String else {
            throw Error.invalidXcode(message: "Expected key 'project' of type string.")
        }

        let targets = if let target = dict["target"] as? String {
            [target]
        } else if let targets = dict["targets"] as? [String] {
            targets
        } else {
            throw Error.invalidXcode(message: "Expected key 'target' of type string or key 'targets' with an array of strings.")
        }

        return .init(
            project: Path(project, relativeTo: basePath),
            targets: targets,
            group: dict["group"] as? String
        )
    }

    private func parseSourcePaths(from dict: [String: Any], basePath: Path) throws -> [SourceFile]? {
        guard let value = dict["sources"] else {
            return nil
        }
        do {
            return try parsePaths(from: value, basePath: basePath).map { SourceFile(path: $0, module: nil) }
        } catch {
            throw ConfigurationParser.Error.invalidSources(message: "\(error)")
        }
    }

    private func parseTemplatePaths(from dict: [String: Any], basePath: Path) throws -> [Path] {
        guard let value = dict["templates"] else {
            throw Error.invalidTemplates(message: "'templates' key is missing.")
        }
        do {
            return try parsePaths(from: value, basePath: basePath)
        } catch {
            throw Error.invalidTemplates(message: "\(error)")
        }
    }

    private func parsePaths(from value: Any, basePath: Path) throws -> [Path] {
        if let dict = value as? [String: [String]], let include = dict["include"] {
            let includes = include.map { Path($0, relativeTo: basePath) }
            let excludes = dict["exclude"]?.map { Path($0, relativeTo: basePath) } ?? []
            return pathResolver.resolve(includes: includes, excludes: excludes)
        } else if let paths = value as? [String] {
            return paths.map { Path($0, relativeTo: basePath) }
        } else if let path = value as? String {
            let path = Path(path, relativeTo: basePath)
            return [path]
        } else {
            throw ConfigurationParser.Error.invalidPaths(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
        }
    }

    private func parseProject(from dict: [String: Any], basePath: Path) throws -> Project? {
        guard let value = dict["project"] else {
            return nil
        }
        return try Project(from: value, basePath: basePath)
    }

    private func parseProjectSourcePaths(from dict: [String: Any], basePath: Path) throws -> [SourceFile]? {
        guard let project = try parseProject(from: dict, basePath: basePath) else {
            return nil
        }

        var sourceFiles: [SourceFile] = []

        let xcodeProj = try xcodeProjFactory.create(from: project.path)
        for target in project.targets {
            let filePaths = xcodeProj.sourceFilesPaths(targetName: target.name, sourceRoot: project.root)
            for filePath in filePaths where !project.exclude.contains(filePath) {
                sourceFiles.append(.init(path: filePath, module: target.module))
            }
            for framework in target.xcframeworks {
                sourceFiles.append(.init(path: framework.swiftInterfacePath, module: target.module))
            }
        }

        return sourceFiles
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
        case invalidXcode(message: String)
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
            "Invalid xcframework\(path.map { " at path '\($0)'" } ?? ""). \(message)"
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
        case let .invalidXcode(message):
            "Invalid xcode. \(message)"
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

private extension Project {
    init(from value: Any, basePath: Path) throws {
        guard let dict = value as? [String: Any] else {
            throw ConfigurationParser.Error.invalidProject(message: "Expected an object.")
        }
        guard let file = dict["file"] as? String else {
            throw ConfigurationParser.Error.invalidProject(message: "Project file path is not provided. Expected string.")
        }

        if let value = dict["target"] as? [[String: Any]] {
            targets = try value.map { try Target(dict: $0, basePath: basePath) }
        } else if let value = dict["target"] as? [String: Any] {
            targets = try [Target(dict: value, basePath: basePath)]
        } else if dict["target"] != nil {
            throw ConfigurationParser.Error.invalidTarget(message: "Expected an object or an array of objects.")
        } else {
            throw ConfigurationParser.Error.invalidProject(message: "'target' key is missing.")
        }

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
