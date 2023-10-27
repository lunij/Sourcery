import XcodeProj

protocol XcodeProjProtocol {
    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path]
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
