import SourceryRuntime

class LoggerMock: Logging {
    enum Call: Equatable {
        case astError(String)
        case astWarning(String)
        case benchmark(String)
        case error(String)
        case info(String)
        case verbose(String)
        case warning(String)
        case output(String)
    }

    var calls: [Call] = []

    var level: LogLevel = .warning
    var messages: [String] = []

    func astError(_ message: String) {
        calls.append(.astError(message))
    }

    func astWarning(_ message: String) {
        calls.append(.astWarning(message))
    }

    func benchmark(_ message: String) {
        calls.append(.benchmark(message))
    }

    func error(_ message: String) {
        calls.append(.error(message))
    }

    func info(_ message: String) {
        calls.append(.info(message))
    }

    func verbose(_ message: String) {
        calls.append(.verbose(message))
    }

    func warning(_ message: String) {
        calls.append(.warning(message))
    }

    func output(_ message: String) {
        calls.append(.output(message))
    }
}
