// Generated using Sourcery

class XcodeProjProtocolMock: XcodeProjProtocol {




    // MARK: - addGroupIfNeeded

    var addGroupIfNeededNamedToSourceRootCallsCount = 0
    var addGroupIfNeededNamedToSourceRootCalled: Bool {
        return addGroupIfNeededNamedToSourceRootCallsCount > 0
    }
    var addGroupIfNeededNamedToSourceRootReceivedArguments: (group: String, parentGroup: PBXGroup, sourceRoot: Path)?
    var addGroupIfNeededNamedToSourceRootReceivedInvocations: [(group: String, parentGroup: PBXGroup, sourceRoot: Path)] = []
    var addGroupIfNeededNamedToSourceRootReturnValue: PBXGroup!
    var addGroupIfNeededNamedToSourceRootClosure: ((String, PBXGroup, Path) -> PBXGroup)?

    func addGroupIfNeeded(named group: String, to parentGroup: PBXGroup, sourceRoot: Path) -> PBXGroup {
        addGroupIfNeededNamedToSourceRootCallsCount += 1
        addGroupIfNeededNamedToSourceRootReceivedArguments = (group: group, parentGroup: parentGroup, sourceRoot: sourceRoot)
        addGroupIfNeededNamedToSourceRootReceivedInvocations.append((group: group, parentGroup: parentGroup, sourceRoot: sourceRoot))
        if let addGroupIfNeededNamedToSourceRootClosure = addGroupIfNeededNamedToSourceRootClosure {
            return addGroupIfNeededNamedToSourceRootClosure(group, parentGroup, sourceRoot)
        } else {
            return addGroupIfNeededNamedToSourceRootReturnValue
        }
    }

    // MARK: - addSourceFile

    var addSourceFileWithToTargetSourceRootThrowableError: Error?
    var addSourceFileWithToTargetSourceRootCallsCount = 0
    var addSourceFileWithToTargetSourceRootCalled: Bool {
        return addSourceFileWithToTargetSourceRootCallsCount > 0
    }
    var addSourceFileWithToTargetSourceRootReceivedArguments: (filePath: Path, group: PBXGroup, target: PBXTarget, sourceRoot: Path)?
    var addSourceFileWithToTargetSourceRootReceivedInvocations: [(filePath: Path, group: PBXGroup, target: PBXTarget, sourceRoot: Path)] = []
    var addSourceFileWithToTargetSourceRootClosure: ((Path, PBXGroup, PBXTarget, Path) throws -> Void)?

    func addSourceFile(with filePath: Path, to group: PBXGroup, target: PBXTarget, sourceRoot: Path) throws {
        if let error = addSourceFileWithToTargetSourceRootThrowableError {
            throw error
        }
        addSourceFileWithToTargetSourceRootCallsCount += 1
        addSourceFileWithToTargetSourceRootReceivedArguments = (filePath: filePath, group: group, target: target, sourceRoot: sourceRoot)
        addSourceFileWithToTargetSourceRootReceivedInvocations.append((filePath: filePath, group: group, target: target, sourceRoot: sourceRoot))
        try addSourceFileWithToTargetSourceRootClosure?(filePath, group, target, sourceRoot)
    }

    // MARK: - rootGroup

    var rootGroupThrowableError: Error?
    var rootGroupCallsCount = 0
    var rootGroupCalled: Bool {
        return rootGroupCallsCount > 0
    }
    var rootGroupReturnValue: PBXGroup?
    var rootGroupClosure: (() throws -> PBXGroup?)?

    func rootGroup() throws -> PBXGroup? {
        if let error = rootGroupThrowableError {
            throw error
        }
        rootGroupCallsCount += 1
        if let rootGroupClosure = rootGroupClosure {
            return try rootGroupClosure()
        } else {
            return rootGroupReturnValue
        }
    }

    // MARK: - sourceFilesPaths

    var sourceFilesPathsTargetNameSourceRootCallsCount = 0
    var sourceFilesPathsTargetNameSourceRootCalled: Bool {
        return sourceFilesPathsTargetNameSourceRootCallsCount > 0
    }
    var sourceFilesPathsTargetNameSourceRootReceivedArguments: (targetName: String, sourceRoot: Path)?
    var sourceFilesPathsTargetNameSourceRootReceivedInvocations: [(targetName: String, sourceRoot: Path)] = []
    var sourceFilesPathsTargetNameSourceRootReturnValue: [Path]!
    var sourceFilesPathsTargetNameSourceRootClosure: ((String, Path) -> [Path])?

    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path] {
        sourceFilesPathsTargetNameSourceRootCallsCount += 1
        sourceFilesPathsTargetNameSourceRootReceivedArguments = (targetName: targetName, sourceRoot: sourceRoot)
        sourceFilesPathsTargetNameSourceRootReceivedInvocations.append((targetName: targetName, sourceRoot: sourceRoot))
        if let sourceFilesPathsTargetNameSourceRootClosure = sourceFilesPathsTargetNameSourceRootClosure {
            return sourceFilesPathsTargetNameSourceRootClosure(targetName, sourceRoot)
        } else {
            return sourceFilesPathsTargetNameSourceRootReturnValue
        }
    }

    // MARK: - target

    var targetNamedCallsCount = 0
    var targetNamedCalled: Bool {
        return targetNamedCallsCount > 0
    }
    var targetNamedReceivedTargetName: String?
    var targetNamedReceivedInvocations: [String] = []
    var targetNamedReturnValue: PBXTarget?
    var targetNamedClosure: ((String) -> PBXTarget?)?

    func target(named targetName: String) -> PBXTarget? {
        targetNamedCallsCount += 1
        targetNamedReceivedTargetName = targetName
        targetNamedReceivedInvocations.append(targetName)
        if let targetNamedClosure = targetNamedClosure {
            return targetNamedClosure(targetName)
        } else {
            return targetNamedReturnValue
        }
    }

    // MARK: - writePBXProj

    var writePBXProjPathOverrideOutputSettingsThrowableError: Error?
    var writePBXProjPathOverrideOutputSettingsCallsCount = 0
    var writePBXProjPathOverrideOutputSettingsCalled: Bool {
        return writePBXProjPathOverrideOutputSettingsCallsCount > 0
    }
    var writePBXProjPathOverrideOutputSettingsReceivedArguments: (path: Path, override: Bool, outputSettings: PBXOutputSettings)?
    var writePBXProjPathOverrideOutputSettingsReceivedInvocations: [(path: Path, override: Bool, outputSettings: PBXOutputSettings)] = []
    var writePBXProjPathOverrideOutputSettingsClosure: ((Path, Bool, PBXOutputSettings) throws -> Void)?

    func writePBXProj(path: Path, override: Bool, outputSettings: PBXOutputSettings) throws {
        if let error = writePBXProjPathOverrideOutputSettingsThrowableError {
            throw error
        }
        writePBXProjPathOverrideOutputSettingsCallsCount += 1
        writePBXProjPathOverrideOutputSettingsReceivedArguments = (path: path, override: override, outputSettings: outputSettings)
        writePBXProjPathOverrideOutputSettingsReceivedInvocations.append((path: path, override: override, outputSettings: outputSettings))
        try writePBXProjPathOverrideOutputSettingsClosure?(path, override, outputSettings)
    }

}
