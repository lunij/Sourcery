// Generated using Sourcery

public class ConfigurationParsingMock: ConfigurationParsing {

    public init() {}



    // MARK: - parse

    public var parseFromBasePathEnvThrowableError: Error?
    public var parseFromBasePathEnvCallsCount = 0
    public var parseFromBasePathEnvCalled: Bool {
        return parseFromBasePathEnvCallsCount > 0
    }
    public var parseFromBasePathEnvReceivedArguments: (string: String, basePath: Path, env: [String: String])?
    public var parseFromBasePathEnvReceivedInvocations: [(string: String, basePath: Path, env: [String: String])] = []
    public var parseFromBasePathEnvReturnValue: [Configuration]!
    public var parseFromBasePathEnvClosure: ((String, Path, [String: String]) throws -> [Configuration])?

    public func parse(from string: String, basePath: Path, env: [String: String]) throws -> [Configuration] {
        if let error = parseFromBasePathEnvThrowableError {
            throw error
        }
        parseFromBasePathEnvCallsCount += 1
        parseFromBasePathEnvReceivedArguments = (string: string, basePath: basePath, env: env)
        parseFromBasePathEnvReceivedInvocations.append((string: string, basePath: basePath, env: env))
        if let parseFromBasePathEnvClosure = parseFromBasePathEnvClosure {
            return try parseFromBasePathEnvClosure(string, basePath, env)
        } else {
            return parseFromBasePathEnvReturnValue
        }
    }

}
