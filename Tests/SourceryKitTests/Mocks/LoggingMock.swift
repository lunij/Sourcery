// Generated using Sourcery

public class LoggingMock: Logging {

    public init() {}

    public var level: LogLevel {
        get { return underlyingLevel }
        set(value) { underlyingLevel = value }
    }
    public var underlyingLevel: LogLevel!


    // MARK: - astError

    public var astErrorCallsCount = 0
    public var astErrorCalled: Bool {
        return astErrorCallsCount > 0
    }
    public var astErrorReceivedMessage: String?
    public var astErrorReceivedInvocations: [String] = []
    public var astErrorClosure: ((String) -> Void)?

    public func astError(_ message: String) {
        astErrorCallsCount += 1
        astErrorReceivedMessage = message
        astErrorReceivedInvocations.append(message)
        astErrorClosure?(message)
    }

    // MARK: - astWarning

    public var astWarningCallsCount = 0
    public var astWarningCalled: Bool {
        return astWarningCallsCount > 0
    }
    public var astWarningReceivedMessage: String?
    public var astWarningReceivedInvocations: [String] = []
    public var astWarningClosure: ((String) -> Void)?

    public func astWarning(_ message: String) {
        astWarningCallsCount += 1
        astWarningReceivedMessage = message
        astWarningReceivedInvocations.append(message)
        astWarningClosure?(message)
    }

    // MARK: - error

    public var errorCallsCount = 0
    public var errorCalled: Bool {
        return errorCallsCount > 0
    }
    public var errorReceivedMessage: String?
    public var errorReceivedInvocations: [String] = []
    public var errorClosure: ((String) -> Void)?

    public func error(_ message: String) {
        errorCallsCount += 1
        errorReceivedMessage = message
        errorReceivedInvocations.append(message)
        errorClosure?(message)
    }

    // MARK: - info

    public var infoCallsCount = 0
    public var infoCalled: Bool {
        return infoCallsCount > 0
    }
    public var infoReceivedMessage: String?
    public var infoReceivedInvocations: [String] = []
    public var infoClosure: ((String) -> Void)?

    public func info(_ message: String) {
        infoCallsCount += 1
        infoReceivedMessage = message
        infoReceivedInvocations.append(message)
        infoClosure?(message)
    }

    // MARK: - verbose

    public var verboseCallsCount = 0
    public var verboseCalled: Bool {
        return verboseCallsCount > 0
    }
    public var verboseReceivedMessage: String?
    public var verboseReceivedInvocations: [String] = []
    public var verboseClosure: ((String) -> Void)?

    public func verbose(_ message: String) {
        verboseCallsCount += 1
        verboseReceivedMessage = message
        verboseReceivedInvocations.append(message)
        verboseClosure?(message)
    }

    // MARK: - warning

    public var warningCallsCount = 0
    public var warningCalled: Bool {
        return warningCallsCount > 0
    }
    public var warningReceivedMessage: String?
    public var warningReceivedInvocations: [String] = []
    public var warningClosure: ((String) -> Void)?

    public func warning(_ message: String) {
        warningCallsCount += 1
        warningReceivedMessage = message
        warningReceivedInvocations.append(message)
        warningClosure?(message)
    }

    // MARK: - output

    public var outputCallsCount = 0
    public var outputCalled: Bool {
        return outputCallsCount > 0
    }
    public var outputReceivedMessage: String?
    public var outputReceivedInvocations: [String] = []
    public var outputClosure: ((String) -> Void)?

    public func output(_ message: String) {
        outputCallsCount += 1
        outputReceivedMessage = message
        outputReceivedInvocations.append(message)
        outputClosure?(message)
    }

}
