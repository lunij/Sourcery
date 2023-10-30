import XcodeProj

protocol XcodeProjProtocol {
    func addSourceFile(at filePath: Path, toGroup: PBXGroup, target: PBXTarget, sourceRoot: Path) throws
    func createGroupIfNeeded(named group: String?, sourceRoot: Path) -> PBXGroup?
    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path]
    func target(named targetName: String) -> PBXTarget?
    func writePBXProj(path: Path, override: Bool, outputSettings: PBXOutputSettings) throws
}

extension XcodeProjProtocol {
    func writePBXProj(path: Path, outputSettings: PBXOutputSettings) throws {
        try writePBXProj(path: path, override: true, outputSettings: outputSettings)
    }
}

extension XcodeProj: XcodeProjProtocol {
    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path] {
        guard let target = target(named: targetName) else {
            return []
        }
        return sourceFilesPaths(target: target, sourceRoot: sourceRoot)
    }
}

protocol XcodeProjFactoryProtocol {
    func create(from path: Path) throws -> XcodeProjProtocol
}

struct XcodeProjFactory: XcodeProjFactoryProtocol {
    func create(from path: Path) throws -> XcodeProjProtocol {
        try XcodeProj(path: path)
    }
}
