import Foundation
import XcodeProj
import PathKit
import Yams
import SourceryRuntime
import QuartzCore

public struct Configuration: Equatable {
    public let sources: Sources
    public let templates: Paths
    public let output: Output
    public let cacheBasePath: Path
    public let forceParse: [String]
    public let parseDocumentation: Bool
    public let baseIndentation: Int
    public let args: [String: NSObject]

    public init(
        sources: Sources,
        templates: Paths,
        output: Output,
        cacheBasePath: Path,
        forceParse: [String],
        parseDocumentation: Bool,
        baseIndentation: Int,
        args: [String: NSObject]
    ) {
        self.sources = sources
        self.templates = templates
        self.output = output
        self.cacheBasePath = cacheBasePath
        self.forceParse = forceParse
        self.parseDocumentation = parseDocumentation
        self.baseIndentation = baseIndentation
        self.args = args
    }

    public init(
        path: Path,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws {
        guard let dict = try Yams.load(yaml: path.read(), .default, Constructor.sourceryContructor(env: env)) as? [String: Any] else {
            throw Configuration.Error.invalidFormat(message: "Expected dictionary.")
        }

        try self.init(dict: dict, relativePath: relativePath)
    }

    public init(dict: [String: Any], relativePath: Path) throws {
        let sources = try Sources(dict: dict, relativePath: relativePath)
        guard !sources.isEmpty else {
            throw Configuration.Error.invalidSources(message: "No sources provided.")
        }
        self.sources = sources

        let templates: Paths
        guard let templatesDict = dict["templates"] else {
            throw Configuration.Error.invalidTemplates(message: "'templates' key is missing.")
        }
        do {
            templates = try Paths(dict: templatesDict, relativePath: relativePath)
        } catch {
            throw Configuration.Error.invalidTemplates(message: "\(error)")
        }
        guard !templates.isEmpty else {
            throw Configuration.Error.invalidTemplates(message: "No templates provided.")
        }
        self.templates = templates

        self.forceParse = dict["forceParse"] as? [String] ?? []

        self.parseDocumentation = dict["parseDocumentation"] as? Bool ?? false

        if let output = dict["output"] as? String {
            self.output = Output(Path(output, relativeTo: relativePath))
        } else if let output = dict["output"] as? [String: Any] {
            self.output = try Output(dict: output, relativePath: relativePath)
        } else {
            throw Configuration.Error.invalidOutput(message: "'output' key is missing or is not a string or object.")
        }

        if let cacheBasePath = dict["cacheBasePath"] as? String {
            self.cacheBasePath = Path(cacheBasePath, relativeTo: relativePath)
        } else if dict["cacheBasePath"] != nil {
            throw Configuration.Error.invalidCacheBasePath(message: "'cacheBasePath' key is not a string.")
        } else {
            self.cacheBasePath = Path.defaultBaseCachePath
        }

        self.baseIndentation = dict["baseIndentation"] as? Int ?? 0
        self.args = dict["args"] as? [String: NSObject] ?? [:]
    }

    public enum Error: Swift.Error {
        case invalidFormat(message: String)
        case invalidSources(message: String)
        case invalidXCFramework(path: Path? = nil, message: String)
        case invalidTemplates(message: String)
        case invalidOutput(message: String)
        case invalidCacheBasePath(message: String)
        case invalidPaths(message: String)
    }
}

extension Configuration.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidFormat(let message):
            return "Invalid config file format. \(message)"
        case .invalidSources(let message):
            return "Invalid sources. \(message)"
        case .invalidXCFramework(let path, let message):
            return "Invalid xcframework\(path.map { " at path '\($0)'" } ?? "")'. \(message)"
        case .invalidTemplates(let message):
            return "Invalid templates. \(message)"
        case .invalidOutput(let message):
            return "Invalid output. \(message)"
        case .invalidCacheBasePath(let message):
            return "Invalid cacheBasePath. \(message)"
        case .invalidPaths(let message):
            return "\(message)"
        }
    }
}

public enum Configurations {
    public static func make(
        path: Path,
        relativePath: Path,
        env: [String: String] = [:]
    ) throws -> [Configuration] {
        guard let dict = try Yams.load(yaml: path.read(), .default, Constructor.sourceryContructor(env: env)) as? [String: Any] else {
            throw Configuration.Error.invalidFormat(message: "Expected dictionary.")
        }

        let start = CFAbsoluteTimeGetCurrent()
        defer {
            Log.benchmark("Resolving configurations took \(CFAbsoluteTimeGetCurrent() - start)")
        }

        if let configurations = dict["configurations"] as? [[String: Any]] {
            return try configurations.map { dict in
                try Configuration(dict: dict, relativePath: relativePath)
            }
        } else {
            return try [Configuration(dict: dict, relativePath: relativePath)]
        }
    }
}

// Copied from https://github.com/realm/SwiftLint/blob/0.29.2/Source/SwiftLintFramework/Models/YamlParser.swift
// and https://github.com/SwiftGen/SwiftGen/blob/6.1.0/Sources/SwiftGenKit/Utils/YAML.swift

private extension Constructor {
    static func sourceryContructor(env: [String: String]) -> Constructor {
        return Constructor(customScalarMap(env: env))
    }

    static func customScalarMap(env: [String: String]) -> ScalarMap {
        var map = defaultScalarMap
        map[.str] = String.constructExpandingEnvVars(env: env)
        return map
    }
}

private extension String {
    static func constructExpandingEnvVars(env: [String: String]) -> (_ scalar: Node.Scalar) -> String? {
        return { (scalar: Node.Scalar) -> String? in
            scalar.string.expandingEnvVars(env: env)
        }
    }

    func expandingEnvVars(env: [String: String]) -> String? {
        // check if entry has an env variable
        guard let match = self.range(of: #"\$\{(.)\w+\}"#, options: .regularExpression) else {
            return self
        }

        // get the env variable as "${ENV_VAR}"
        let key = String(self[match])

        // get the env variable as "ENV_VAR" - note missing $ and brackets
        let keyString = String(key[2..<key.count-1])

        guard let value = env[keyString] else { return "" }

        return self.replacingOccurrences(of: key, with: value)
    }
}

private extension StringProtocol {
    subscript(bounds: CountableClosedRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start..<end]
    }

    subscript(bounds: CountableRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(start, offsetBy: bounds.count)
        return self[start..<end]
    }
}
