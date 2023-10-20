import Darwin
import Foundation

public var logger: Logging = Logger()

// sourcery: AutoMockable
public protocol Logging {
    var level: LogLevel { get }

    func astError(_ message: String)
    func astWarning(_ message: String)
    func error(_ message: String)
    func info(_ message: String)
    func verbose(_ message: String)
    func warning(_ message: String)
    func output(_ message: String)
}

public extension Logging {
    func error(_ error: Error) {
        self.error(String(describing: error))
    }

    func warning(_ error: Error) {
        warning(String(describing: error))
    }
}

public enum LogLevel: Int {
    case error
    case warning
    case info
    case verbose
}

public class Logger: Logging {
    public let level: LogLevel

    public let logAST: Bool

    public init(
        level: LogLevel = .warning,
        logAST: Bool = false
    ) {
        self.level = level
        self.logAST = logAST
    }

    public func output(_ message: String) {
        print(message)
    }

    public func error(_ message: String) {
        log(level: .error, "error: \(message)")
        // to return error when running swift templates which is done in a different process
        if ProcessInfo().processName != "Sourcery" {
            fputs("\(message)", stderr)
        }
    }

    public func warning(_ message: String) {
        log(level: .warning, "warning: \(message)")
    }

    public func astWarning(_ message: String) {
        guard logAST else { return }
        log(level: .warning, "ast warning: \(message)")
    }

    public func astError(_ message: String) {
        guard logAST else { return }
        log(level: .error, "ast error: \(message)")
    }

    public func verbose(_ message: String) {
        log(level: .verbose, message)
    }

    public func info(_ message: String) {
        log(level: .info, message)
    }

    func log(level: LogLevel, _ message: String) {
        guard level.rawValue <= self.level.rawValue else { return }
        print(message)
    }
}
