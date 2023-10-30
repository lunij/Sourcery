@testable import SourceryKit

class XcodeProjModifierMock: XcodeProjModifying {
    enum Call: Equatable {
        case link(Path)
        case save
    }

    var calls: [Call] = []

    func link(path: Path) {
        calls.append(.link(path))
    }

    var saveError: Error?
    func save() throws {
        calls.append(.save)
        if let saveError { throw saveError }
    }
}

class XcodeProjModifierFactoryMock: XcodeProjModifierMaking {
    enum Call: Equatable {
        case makeModifier
    }

    var calls: [Call] = []

    var makeModifierError: Error?
    var makeModifierReturnValue: XcodeProjModifying?
    func makeModifier(from config: Configuration) throws -> XcodeProjModifying? {
        calls.append(.makeModifier)
        if let makeModifierError { throw makeModifierError }
        if let makeModifierReturnValue { return makeModifierReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
