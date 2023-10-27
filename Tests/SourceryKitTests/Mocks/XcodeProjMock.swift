@testable import SourceryKit

class XcodeProjMock: XcodeProjProtocol {
    enum Call: Equatable {
        case sourceFilesPaths(String, Path)
    }

    var calls: [Call] = []

    var sourceFilesPathsReturnValue: [Path]?
    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path] {
        calls.append(.sourceFilesPaths(targetName, sourceRoot))
        if let sourceFilesPathsReturnValue { return sourceFilesPathsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}

class XcodeProjFactoryMock: XcodeProjFactoryProtocol {
    enum Call: Equatable {
        case create(Path)
    }

    var calls: [Call] = []

    var createError: Error?
    var createReturnValue: XcodeProjProtocol?
    func create(from path: Path) throws -> XcodeProjProtocol {
        calls.append(.create(path))
        if let createError { throw createError }
        if let createReturnValue { return createReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
