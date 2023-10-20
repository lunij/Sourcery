import SourceryKit

class ConfigurationParserMock: ConfigurationParsing {
    enum Call: Equatable {
        case parseConfigurations(String, Path, [String: String])
        case parse(String, Path, [String: String])
    }

    var calls: [Call] = []

    var parseConfigurationsError: Error?
    var parseConfigurationsReturnValue: [Configuration]?
    func parseConfigurations(from yaml: String, relativePath: Path, env: [String: String]) throws -> [Configuration] {
        calls.append(.parseConfigurations(yaml, relativePath, env))
        if let parseConfigurationsError { throw parseConfigurationsError }
        if let parseConfigurationsReturnValue { return parseConfigurationsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var parseError: Error?
    var parseReturnValue: Configuration?
    func parse(from yaml: String, relativePath: Path, env: [String: String]) throws -> Configuration {
        calls.append(.parse(yaml, relativePath, env))
        if let parseError { throw parseError }
        if let parseReturnValue { return parseReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
