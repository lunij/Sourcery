import SourceryKit

class ConfigurationParserMock: ConfigurationParsing {
    enum Call: Equatable {
        case parse(String, Path, [String: String])
    }

    var calls: [Call] = []

    var parseError: Error?
    var parseReturnValue: [Configuration]?
    func parse(from yaml: String, basePath: Path, env: [String: String]) throws -> [Configuration] {
        calls.append(.parse(yaml, basePath, env))
        if let parseError { throw parseError }
        if let parseReturnValue { return parseReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
