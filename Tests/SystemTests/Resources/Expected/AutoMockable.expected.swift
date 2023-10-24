// Generated using Sourcery

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

public class AccessLevelProtocolMock: AccessLevelProtocol {
    public init() {}

    public var company: String?
    public var name: String {
        get { underlyingName }
        set(value) { underlyingName = value }
    }

    public var underlyingName: String!

    // MARK: - loadConfiguration

    public var loadConfigurationCallsCount = 0
    public var loadConfigurationCalled: Bool {
        loadConfigurationCallsCount > 0
    }

    public var loadConfigurationReturnValue: String?
    public var loadConfigurationClosure: (() -> String?)?

    public func loadConfiguration() -> String? {
        loadConfigurationCallsCount += 1
        if let loadConfigurationClosure {
            return loadConfigurationClosure()
        } else {
            return loadConfigurationReturnValue
        }
    }
}

class AnnotatedProtocolMock: AnnotatedProtocol {
    // MARK: - sayHelloWith

    var sayHelloWithNameCallsCount = 0
    var sayHelloWithNameCalled: Bool {
        sayHelloWithNameCallsCount > 0
    }

    var sayHelloWithNameReceivedName: String?
    var sayHelloWithNameReceivedInvocations: [String] = []
    var sayHelloWithNameClosure: ((String) -> Void)?

    func sayHelloWith(name: String) {
        sayHelloWithNameCallsCount += 1
        sayHelloWithNameReceivedName = name
        sayHelloWithNameReceivedInvocations.append(name)
        sayHelloWithNameClosure?(name)
    }
}

class AsyncProtocolMock: AsyncProtocol {
    // MARK: - callAsync

    var callAsyncParameterCallsCount = 0
    var callAsyncParameterCalled: Bool {
        callAsyncParameterCallsCount > 0
    }

    var callAsyncParameterReceivedParameter: Int?
    var callAsyncParameterReceivedInvocations: [Int] = []
    var callAsyncParameterReturnValue: String!
    var callAsyncParameterClosure: ((Int) async -> String)?

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func callAsync(parameter: Int) async -> String {
        callAsyncParameterCallsCount += 1
        callAsyncParameterReceivedParameter = parameter
        callAsyncParameterReceivedInvocations.append(parameter)
        if let callAsyncParameterClosure {
            return await callAsyncParameterClosure(parameter)
        } else {
            return callAsyncParameterReturnValue
        }
    }

    // MARK: - callAsyncAndThrow

    var callAsyncAndThrowParameterThrowableError: Error?
    var callAsyncAndThrowParameterCallsCount = 0
    var callAsyncAndThrowParameterCalled: Bool {
        callAsyncAndThrowParameterCallsCount > 0
    }

    var callAsyncAndThrowParameterReceivedParameter: Int?
    var callAsyncAndThrowParameterReceivedInvocations: [Int] = []
    var callAsyncAndThrowParameterReturnValue: String!
    var callAsyncAndThrowParameterClosure: ((Int) async throws -> String)?

    func callAsyncAndThrow(parameter: Int) async throws -> String {
        if let error = callAsyncAndThrowParameterThrowableError {
            throw error
        }
        callAsyncAndThrowParameterCallsCount += 1
        callAsyncAndThrowParameterReceivedParameter = parameter
        callAsyncAndThrowParameterReceivedInvocations.append(parameter)
        if let callAsyncAndThrowParameterClosure {
            return try await callAsyncAndThrowParameterClosure(parameter)
        } else {
            return callAsyncAndThrowParameterReturnValue
        }
    }

    // MARK: - callAsyncVoid

    var callAsyncVoidParameterCallsCount = 0
    var callAsyncVoidParameterCalled: Bool {
        callAsyncVoidParameterCallsCount > 0
    }

    var callAsyncVoidParameterReceivedParameter: Int?
    var callAsyncVoidParameterReceivedInvocations: [Int] = []
    var callAsyncVoidParameterClosure: ((Int) async -> Void)?

    func callAsyncVoid(parameter: Int) async {
        callAsyncVoidParameterCallsCount += 1
        callAsyncVoidParameterReceivedParameter = parameter
        callAsyncVoidParameterReceivedInvocations.append(parameter)
        await callAsyncVoidParameterClosure?(parameter)
    }

    // MARK: - callAsyncAndThrowVoid

    var callAsyncAndThrowVoidParameterThrowableError: Error?
    var callAsyncAndThrowVoidParameterCallsCount = 0
    var callAsyncAndThrowVoidParameterCalled: Bool {
        callAsyncAndThrowVoidParameterCallsCount > 0
    }

    var callAsyncAndThrowVoidParameterReceivedParameter: Int?
    var callAsyncAndThrowVoidParameterReceivedInvocations: [Int] = []
    var callAsyncAndThrowVoidParameterClosure: ((Int) async throws -> Void)?

    func callAsyncAndThrowVoid(parameter: Int) async throws {
        if let error = callAsyncAndThrowVoidParameterThrowableError {
            throw error
        }
        callAsyncAndThrowVoidParameterCallsCount += 1
        callAsyncAndThrowVoidParameterReceivedParameter = parameter
        callAsyncAndThrowVoidParameterReceivedInvocations.append(parameter)
        try await callAsyncAndThrowVoidParameterClosure?(parameter)
    }
}

class AsyncThrowingVariablesProtocolMock: AsyncThrowingVariablesProtocol {
    var titleCallsCount = 0
    var titleCalled: Bool {
        titleCallsCount > 0
    }

    var title: String? {
        get async throws {
            if let error = titleThrowableError {
                throw error
            }
            titleCallsCount += 1
            if let titleClosure {
                return try await titleClosure()
            } else {
                return underlyingTitle
            }
        }
    }

    var underlyingTitle: String?
    var titleThrowableError: Error?
    var titleClosure: (() async throws -> String?)?
    var firstNameCallsCount = 0
    var firstNameCalled: Bool {
        firstNameCallsCount > 0
    }

    var firstName: String {
        get async throws {
            if let error = firstNameThrowableError {
                throw error
            }
            firstNameCallsCount += 1
            if let firstNameClosure {
                return try await firstNameClosure()
            } else {
                return underlyingFirstName
            }
        }
    }

    var underlyingFirstName: String!
    var firstNameThrowableError: Error?
    var firstNameClosure: (() async throws -> String)?
}

class AsyncVariablesProtocolMock: AsyncVariablesProtocol {
    var titleCallsCount = 0
    var titleCalled: Bool {
        titleCallsCount > 0
    }

    var title: String? {
        get async {
            titleCallsCount += 1
            if let titleClosure {
                return await titleClosure()
            } else {
                return underlyingTitle
            }
        }
    }

    var underlyingTitle: String?
    var titleClosure: (() async -> String?)?
    var firstNameCallsCount = 0
    var firstNameCalled: Bool {
        firstNameCallsCount > 0
    }

    var firstName: String {
        get async {
            firstNameCallsCount += 1
            if let firstNameClosure {
                return await firstNameClosure()
            } else {
                return underlyingFirstName
            }
        }
    }

    var underlyingFirstName: String!
    var firstNameClosure: (() async -> String)?
}

class BasicProtocolMock: BasicProtocol {
    // MARK: - loadConfiguration

    var loadConfigurationCallsCount = 0
    var loadConfigurationCalled: Bool {
        loadConfigurationCallsCount > 0
    }

    var loadConfigurationReturnValue: String?
    var loadConfigurationClosure: (() -> String?)?

    func loadConfiguration() -> String? {
        loadConfigurationCallsCount += 1
        if let loadConfigurationClosure {
            return loadConfigurationClosure()
        } else {
            return loadConfigurationReturnValue
        }
    }

    // MARK: - save

    var saveConfigurationCallsCount = 0
    var saveConfigurationCalled: Bool {
        saveConfigurationCallsCount > 0
    }

    var saveConfigurationReceivedConfiguration: String?
    var saveConfigurationReceivedInvocations: [String] = []
    var saveConfigurationClosure: ((String) -> Void)?

    func save(configuration: String) {
        saveConfigurationCallsCount += 1
        saveConfigurationReceivedConfiguration = configuration
        saveConfigurationReceivedInvocations.append(configuration)
        saveConfigurationClosure?(configuration)
    }
}

class ClosureProtocolMock: ClosureProtocol {
    // MARK: - setClosure

    var setClosureCallsCount = 0
    var setClosureCalled: Bool {
        setClosureCallsCount > 0
    }

    var setClosureReceivedClosure: (() -> Void)?
    var setClosureReceivedInvocations: [() -> Void] = []
    var setClosureClosure: ((@escaping () -> Void) -> Void)?

    func setClosure(_ closure: @escaping () -> Void) {
        setClosureCallsCount += 1
        setClosureReceivedClosure = closure
        setClosureReceivedInvocations.append(closure)
        setClosureClosure?(closure)
    }
}

class CurrencyPresenterMock: CurrencyPresenter {
    // MARK: - showSourceCurrency

    var showSourceCurrencyCallsCount = 0
    var showSourceCurrencyCalled: Bool {
        showSourceCurrencyCallsCount > 0
    }

    var showSourceCurrencyReceivedCurrency: String?
    var showSourceCurrencyReceivedInvocations: [String] = []
    var showSourceCurrencyClosure: ((String) -> Void)?

    func showSourceCurrency(_ currency: String) {
        showSourceCurrencyCallsCount += 1
        showSourceCurrencyReceivedCurrency = currency
        showSourceCurrencyReceivedInvocations.append(currency)
        showSourceCurrencyClosure?(currency)
    }
}

class ExtendableProtocolMock: ExtendableProtocol {
    var canReport: Bool {
        get { underlyingCanReport }
        set(value) { underlyingCanReport = value }
    }

    var underlyingCanReport: Bool!

    // MARK: - report

    var reportMessageCallsCount = 0
    var reportMessageCalled: Bool {
        reportMessageCallsCount > 0
    }

    var reportMessageReceivedMessage: String?
    var reportMessageReceivedInvocations: [String] = []
    var reportMessageClosure: ((String) -> Void)?

    func report(message: String) {
        reportMessageCallsCount += 1
        reportMessageReceivedMessage = message
        reportMessageReceivedInvocations.append(message)
        reportMessageClosure?(message)
    }
}

class FunctionWithAttributesMock: FunctionWithAttributes {
    // MARK: - callOneAttribute

    var callOneAttributeCallsCount = 0
    var callOneAttributeCalled: Bool {
        callOneAttributeCallsCount > 0
    }

    var callOneAttributeReturnValue: String!
    var callOneAttributeClosure: (() -> String)?

    @discardableResult
    func callOneAttribute() -> String {
        callOneAttributeCallsCount += 1
        if let callOneAttributeClosure {
            return callOneAttributeClosure()
        } else {
            return callOneAttributeReturnValue
        }
    }

    // MARK: - callTwoAttributes

    var callTwoAttributesCallsCount = 0
    var callTwoAttributesCalled: Bool {
        callTwoAttributesCallsCount > 0
    }

    var callTwoAttributesReturnValue: Int!
    var callTwoAttributesClosure: (() -> Int)?

    @available(macOS 10.15, *)
    @discardableResult
    func callTwoAttributes() -> Int {
        callTwoAttributesCallsCount += 1
        if let callTwoAttributesClosure {
            return callTwoAttributesClosure()
        } else {
            return callTwoAttributesReturnValue
        }
    }

    // MARK: - callRepeatedAttributes

    var callRepeatedAttributesCallsCount = 0
    var callRepeatedAttributesCalled: Bool {
        callRepeatedAttributesCallsCount > 0
    }

    var callRepeatedAttributesReturnValue: Bool!
    var callRepeatedAttributesClosure: (() -> Bool)?

    @available(iOS 13.0, *)
    @available(macOS 10.15, *)
    @discardableResult
    func callRepeatedAttributes() -> Bool {
        callRepeatedAttributesCallsCount += 1
        if let callRepeatedAttributesClosure {
            return callRepeatedAttributesClosure()
        } else {
            return callRepeatedAttributesReturnValue
        }
    }
}

class FunctionWithClosureReturnTypeMock: FunctionWithClosureReturnType {
    // MARK: - get

    var getCallsCount = 0
    var getCalled: Bool {
        getCallsCount > 0
    }

    var getReturnValue: (() -> Void)!
    var getClosure: (() -> () -> Void)?

    func get() -> () -> Void {
        getCallsCount += 1
        if let getClosure {
            return getClosure()
        } else {
            return getReturnValue
        }
    }

    // MARK: - getOptional

    var getOptionalCallsCount = 0
    var getOptionalCalled: Bool {
        getOptionalCallsCount > 0
    }

    var getOptionalReturnValue: (() -> Void)?
    var getOptionalClosure: (() -> (() -> Void)?)?

    func getOptional() -> (() -> Void)? {
        getOptionalCallsCount += 1
        if let getOptionalClosure {
            return getOptionalClosure()
        } else {
            return getOptionalReturnValue
        }
    }
}

class FunctionWithMultilineDeclarationMock: FunctionWithMultilineDeclaration {
    // MARK: - start

    var startCarOfCallsCount = 0
    var startCarOfCalled: Bool {
        startCarOfCallsCount > 0
    }

    var startCarOfReceivedArguments: (car: String, model: String)?
    var startCarOfReceivedInvocations: [(car: String, model: String)] = []
    var startCarOfClosure: ((String, String) -> Void)?

    func start(car: String, of model: String) {
        startCarOfCallsCount += 1
        startCarOfReceivedArguments = (car: car, model: model)
        startCarOfReceivedInvocations.append((car: car, model: model))
        startCarOfClosure?(car, model)
    }
}

class ImplicitlyUnwrappedOptionalReturnValueProtocolMock: ImplicitlyUnwrappedOptionalReturnValueProtocol {
    // MARK: - implicitReturn

    var implicitReturnCallsCount = 0
    var implicitReturnCalled: Bool {
        implicitReturnCallsCount > 0
    }

    var implicitReturnReturnValue: String!
    var implicitReturnClosure: (() -> String?)?

    func implicitReturn() -> String! {
        implicitReturnCallsCount += 1
        if let implicitReturnClosure {
            return implicitReturnClosure()
        } else {
            return implicitReturnReturnValue
        }
    }
}

class InitializationProtocolMock: InitializationProtocol {
    // MARK: - init

    var initIntParameterStringParameterOptionalParameterReceivedArguments: (intParameter: Int, stringParameter: String, optionalParameter: String?)?
    var initIntParameterStringParameterOptionalParameterReceivedInvocations: [(intParameter: Int, stringParameter: String, optionalParameter: String?)] = []
    var initIntParameterStringParameterOptionalParameterClosure: ((Int, String, String?) -> Void)?

    required init(intParameter: Int, stringParameter: String, optionalParameter: String?) {
        initIntParameterStringParameterOptionalParameterReceivedArguments = (intParameter: intParameter, stringParameter: stringParameter, optionalParameter: optionalParameter)
        initIntParameterStringParameterOptionalParameterReceivedInvocations.append((intParameter: intParameter, stringParameter: stringParameter, optionalParameter: optionalParameter))
        initIntParameterStringParameterOptionalParameterClosure?(intParameter, stringParameter, optionalParameter)
    }

    // MARK: - start

    var startCallsCount = 0
    var startCalled: Bool {
        startCallsCount > 0
    }

    var startClosure: (() -> Void)?

    func start() {
        startCallsCount += 1
        startClosure?()
    }

    // MARK: - stop

    var stopCallsCount = 0
    var stopCalled: Bool {
        stopCallsCount > 0
    }

    var stopClosure: (() -> Void)?

    func stop() {
        stopCallsCount += 1
        stopClosure?()
    }
}

class MultiClosureProtocolMock: MultiClosureProtocol {
    // MARK: - setClosure

    var setClosureNameCallsCount = 0
    var setClosureNameCalled: Bool {
        setClosureNameCallsCount > 0
    }

    var setClosureNameReceivedArguments: (name: String, closure: () -> Void)?
    var setClosureNameReceivedInvocations: [(name: String, closure: () -> Void)] = []
    var setClosureNameClosure: ((String, @escaping () -> Void) -> Void)?

    func setClosure(name: String, _ closure: @escaping () -> Void) {
        setClosureNameCallsCount += 1
        setClosureNameReceivedArguments = (name: name, closure: closure)
        setClosureNameReceivedInvocations.append((name: name, closure: closure))
        setClosureNameClosure?(name, closure)
    }
}

class MultiNonEscapingClosureProtocolMock: MultiNonEscapingClosureProtocol {
    // MARK: - executeClosure

    var executeClosureNameCallsCount = 0
    var executeClosureNameCalled: Bool {
        executeClosureNameCallsCount > 0
    }

    var executeClosureNameClosure: ((String, () -> Void) -> Void)?

    func executeClosure(name: String, _ closure: () -> Void) {
        executeClosureNameCallsCount += 1
        executeClosureNameClosure?(name, closure)
    }
}

class NonEscapingClosureProtocolMock: NonEscapingClosureProtocol {
    // MARK: - executeClosure

    var executeClosureCallsCount = 0
    var executeClosureCalled: Bool {
        executeClosureCallsCount > 0
    }

    var executeClosureClosure: ((() -> Void) -> Void)?

    func executeClosure(_ closure: () -> Void) {
        executeClosureCallsCount += 1
        executeClosureClosure?(closure)
    }
}

class ReservedWordsProtocolMock: ReservedWordsProtocol {
    // MARK: - `continue`

    var continueWithCallsCount = 0
    var continueWithCalled: Bool {
        continueWithCallsCount > 0
    }

    var continueWithReceivedMessage: String?
    var continueWithReceivedInvocations: [String] = []
    var continueWithReturnValue: String!
    var continueWithClosure: ((String) -> String)?

    func `continue`(with message: String) -> String {
        continueWithCallsCount += 1
        continueWithReceivedMessage = message
        continueWithReceivedInvocations.append(message)
        if let continueWithClosure {
            return continueWithClosure(message)
        } else {
            return continueWithReturnValue
        }
    }
}

class SameShortMethodNamesProtocolMock: SameShortMethodNamesProtocol {
    // MARK: - start

    var startCarOfCallsCount = 0
    var startCarOfCalled: Bool {
        startCarOfCallsCount > 0
    }

    var startCarOfReceivedArguments: (car: String, model: String)?
    var startCarOfReceivedInvocations: [(car: String, model: String)] = []
    var startCarOfClosure: ((String, String) -> Void)?

    func start(car: String, of model: String) {
        startCarOfCallsCount += 1
        startCarOfReceivedArguments = (car: car, model: model)
        startCarOfReceivedInvocations.append((car: car, model: model))
        startCarOfClosure?(car, model)
    }

    // MARK: - start

    var startPlaneOfCallsCount = 0
    var startPlaneOfCalled: Bool {
        startPlaneOfCallsCount > 0
    }

    var startPlaneOfReceivedArguments: (plane: String, model: String)?
    var startPlaneOfReceivedInvocations: [(plane: String, model: String)] = []
    var startPlaneOfClosure: ((String, String) -> Void)?

    func start(plane: String, of model: String) {
        startPlaneOfCallsCount += 1
        startPlaneOfReceivedArguments = (plane: plane, model: model)
        startPlaneOfReceivedInvocations.append((plane: plane, model: model))
        startPlaneOfClosure?(plane, model)
    }
}

class SingleOptionalParameterFunctionMock: SingleOptionalParameterFunction {
    // MARK: - send

    var sendMessageCallsCount = 0
    var sendMessageCalled: Bool {
        sendMessageCallsCount > 0
    }

    var sendMessageReceivedMessage: String?
    var sendMessageReceivedInvocations: [String?] = []
    var sendMessageClosure: ((String?) -> Void)?

    func send(message: String?) {
        sendMessageCallsCount += 1
        sendMessageReceivedMessage = message
        sendMessageReceivedInvocations.append(message)
        sendMessageClosure?(message)
    }
}

class StaticMethodProtocolMock: StaticMethodProtocol {
    static func reset() {
        // MARK: - staticFunction

        staticFunctionCallsCount = 0
        staticFunctionReceived = nil
        staticFunctionReceivedInvocations = []
        staticFunctionClosure = nil
    }

    // MARK: - staticFunction

    static var staticFunctionCallsCount = 0
    static var staticFunctionCalled: Bool {
        staticFunctionCallsCount > 0
    }

    static var staticFunctionReceived: String?
    static var staticFunctionReceivedInvocations: [String] = []
    static var staticFunctionReturnValue: String!
    static var staticFunctionClosure: ((String) -> String)?

    static func staticFunction(_: String) -> String {
        staticFunctionCallsCount += 1
        staticFunctionReceived =
            staticFunctionReceivedInvocations.append()
        if let staticFunctionClosure {
            return staticFunctionClosure()
        } else {
            return staticFunctionReturnValue
        }
    }
}

class ThrowableProtocolMock: ThrowableProtocol {
    // MARK: - doOrThrow

    var doOrThrowThrowableError: Error?
    var doOrThrowCallsCount = 0
    var doOrThrowCalled: Bool {
        doOrThrowCallsCount > 0
    }

    var doOrThrowReturnValue: String!
    var doOrThrowClosure: (() throws -> String)?

    func doOrThrow() throws -> String {
        if let error = doOrThrowThrowableError {
            throw error
        }
        doOrThrowCallsCount += 1
        if let doOrThrowClosure {
            return try doOrThrowClosure()
        } else {
            return doOrThrowReturnValue
        }
    }

    // MARK: - doOrThrowVoid

    var doOrThrowVoidThrowableError: Error?
    var doOrThrowVoidCallsCount = 0
    var doOrThrowVoidCalled: Bool {
        doOrThrowVoidCallsCount > 0
    }

    var doOrThrowVoidClosure: (() throws -> Void)?

    func doOrThrowVoid() throws {
        if let error = doOrThrowVoidThrowableError {
            throw error
        }
        doOrThrowVoidCallsCount += 1
        try doOrThrowVoidClosure?()
    }
}

class ThrowingVariablesProtocolMock: ThrowingVariablesProtocol {
    var titleCallsCount = 0
    var titleCalled: Bool {
        titleCallsCount > 0
    }

    var title: String? {
        get throws {
            if let error = titleThrowableError {
                throw error
            }
            titleCallsCount += 1
            if let titleClosure {
                return try titleClosure()
            } else {
                return underlyingTitle
            }
        }
    }

    var underlyingTitle: String?
    var titleThrowableError: Error?
    var titleClosure: (() throws -> String?)?
    var firstNameCallsCount = 0
    var firstNameCalled: Bool {
        firstNameCallsCount > 0
    }

    var firstName: String {
        get throws {
            if let error = firstNameThrowableError {
                throw error
            }
            firstNameCallsCount += 1
            if let firstNameClosure {
                return try firstNameClosure()
            } else {
                return underlyingFirstName
            }
        }
    }

    var underlyingFirstName: String!
    var firstNameThrowableError: Error?
    var firstNameClosure: (() throws -> String)?
}

class VariablesProtocolMock: VariablesProtocol {
    var company: String?
    var name: String {
        get { underlyingName }
        set(value) { underlyingName = value }
    }

    var underlyingName: String!
    var age: Int {
        get { underlyingAge }
        set(value) { underlyingAge = value }
    }

    var underlyingAge: Int!
    var kids: [String] = []
    var universityMarks: [String: Int] = [:]
}
