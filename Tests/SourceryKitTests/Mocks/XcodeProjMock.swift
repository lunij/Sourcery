import XcodeProj
@testable import SourceryKit

class XcodeProjMock: XcodeProjProtocol {
    enum Call: Equatable {
        case addGroupIfNeeded(String, Path)
        case addSourceFile(Path)
        case rootGroup
        case sourceFilesPaths(String, Path)
        case target(String)
        case writePBXProj(Path, Bool)
    }

    var calls: [Call] = []

    var addGroupIfNeededReturnValue: PBXGroup?
    func addGroupIfNeeded(named group: String, to parentGroup: PBXGroup, sourceRoot: Path) -> PBXGroup {
        calls.append(.addGroupIfNeeded(group, sourceRoot))
        if let addGroupIfNeededReturnValue { return addGroupIfNeededReturnValue }
        preconditionFailure("Mock needs to be configured")
    }

    var addSourceFileError: Error?
    func addSourceFile(with filePath: Path, to group: PBXGroup, target: PBXTarget, sourceRoot: Path) throws {
        calls.append(.addSourceFile(filePath))
        if let addSourceFileError { throw addSourceFileError }
    }

    var rootGroupError: Error?
    var rootGroupReturnValue: PBXGroup?
    func rootGroup() throws -> PBXGroup? {
        calls.append(.rootGroup)
        if let rootGroupError { throw rootGroupError }
        return rootGroupReturnValue
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
        return targetReturnValue
    }

    var writePBXProjError: Error?
    func writePBXProj(path: Path, override: Bool, outputSettings: PBXOutputSettings) throws {
        calls.append(.writePBXProj(path, override))
        if let writePBXProjError { throw writePBXProjError }
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
