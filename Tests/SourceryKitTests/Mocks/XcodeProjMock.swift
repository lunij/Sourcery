import XcodeProj
@testable import SourceryKit

class XcodeProjMock: XcodeProjProtocol {
    enum Call: Equatable {
        case addSourceFile(Path)
        case createGroupIfNeeded(String?, Path)
        case sourceFilesPaths(String, Path)
        case target(String)
        case writePBXProj(Path, Bool)
    }

    var calls: [Call] = []

    var addSourceFileError: Error?
    func addSourceFile(at filePath: Path, toGroup: PBXGroup, target: PBXTarget, sourceRoot: Path) throws {
        calls.append(.addSourceFile(filePath))
        if let addSourceFileError { throw addSourceFileError }
    }

    var createGroupIfNeededReturnValue: PBXGroup?
    func createGroupIfNeeded(named group: String?, sourceRoot: Path) -> PBXGroup? {
        calls.append(.createGroupIfNeeded(group, sourceRoot))
        if let createGroupIfNeededReturnValue { return createGroupIfNeededReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var sourceFilesPathsReturnValue: [Path]?
    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path] {
        calls.append(.sourceFilesPaths(targetName, sourceRoot))
        if let sourceFilesPathsReturnValue { return sourceFilesPathsReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var targetReturnValue: PBXTarget?
    func target(named targetName: String) -> PBXTarget? {
        calls.append(.target(targetName))
        if let targetReturnValue { return targetReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var writePBXProjError: Error?
    func writePBXProj(path: Path, override: Bool, outputSettings: PBXOutputSettings) throws {
        calls.append(.writePBXProj(path, override))
        if let writePBXProjError { throw writePBXProjError }
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
