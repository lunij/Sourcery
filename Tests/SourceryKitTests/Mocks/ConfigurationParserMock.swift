import SourceryKit

class ConfigurationParserMock: ConfigurationParsing {
    enum Call: Equatable {
        case parseConfigurations(Path, Path, [String: String])
        case parse(Path, Path, [String: String])
    }

    var calls: [Call] = []

    var parseConfigurationsError: Error?
    var parseConfigurationsReturnValue: [Configuration]?
    func parseConfigurations(path: Path, relativePath: Path, env: [String: String]) throws -> [Configuration] {
        calls.append(.parseConfigurations(path, relativePath, env))
        if let parseConfigurationsError { throw parseConfigurationsError }
        if let parseConfigurationsReturnValue { return parseConfigurationsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var parseError: Error?
    var parseReturnValue: Configuration?
    func parse(path: Path, relativePath: Path, env: [String: String]) throws -> Configuration {
        calls.append(.parse(path, relativePath, env))
        if let parseError { throw parseError }
        if let parseReturnValue { return parseReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
