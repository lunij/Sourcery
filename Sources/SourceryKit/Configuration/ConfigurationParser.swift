import Foundation
import QuartzCore
import SourceryRuntime
import Yams

public protocol ConfigurationParsing {
    func parseConfigurations(path: Path, relativePath: Path, env: [String: String]) throws -> [Configuration]
    func parse(path: Path, relativePath: Path, env: [String: String]) throws -> Configuration
}

class ConfigurationParser: ConfigurationParsing {
    func parseConfigurations(
        path: Path,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws -> [Configuration] {
        guard let dict = try Yams.load(yaml: path.read(), .default, Constructor(.customScalarMap(env: env))) as? [String: Any] else {
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
        path: Path,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws -> Configuration {
        guard let dict = try Yams.load(yaml: path.read(), .default, Constructor(.customScalarMap(env: env))) as? [String: Any] else {
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
        case .invalidFormat(let message):
            "Invalid config file format. \(message)"
        case .invalidSources(let message):
            "Invalid sources. \(message)"
        case .invalidXCFramework(let path, let message):
            "Invalid xcframework\(path.map { " at path '\($0)'" } ?? "")'. \(message)"
        case .invalidTemplates(let message):
            "Invalid templates. \(message)"
        case .invalidOutput(let message):
            "Invalid output. \(message)"
        case .invalidCacheBasePath(let message):
            "Invalid cacheBasePath. \(message)"
        case .invalidPaths(let message):
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
