import SourceryRuntime

protocol XcodeProjModifierMaking {
    func makeModifier(from config: Configuration) throws -> XcodeProjModifying?
}

class XcodeProjModifierFactory: XcodeProjModifierMaking {
    private let xcodeProjFactory: XcodeProjFactoryProtocol

    init(xcodeProjFactory: XcodeProjFactoryProtocol = XcodeProjFactory()) {
        self.xcodeProjFactory = xcodeProjFactory
    }

    func makeModifier(from config: Configuration) throws -> XcodeProjModifying? {
        if let xcode = config.xcode {
            let xcodeProj = try xcodeProjFactory.create(from: xcode.project)
            return XcodeProjModifier(xcode: xcode, xcodeProj: xcodeProj)
        } else {
            return nil
        }
    }
}

protocol XcodeProjModifying {
    func link(path: Path)
    func save() throws
}

class XcodeProjModifier: XcodeProjModifying {
    let xcode: Xcode
    let xcodeProj: XcodeProjProtocol

    init(xcode: Xcode, xcodeProj: XcodeProjProtocol) {
        self.xcode = xcode
        self.xcodeProj = xcodeProj
    }

    func link(path: Path) {
        for target in xcode.targets {
            addSourceFile(at: path, target: target, group: xcode.group)
        }
    }

    private func addSourceFile(at path: Path, target: String, group: String?) {
        guard let target = xcodeProj.target(named: target) else {
            logger.warning("Unable to find target \(target)")
            return
        }

        let sourceRoot = xcode.project.parent()

        guard let fileGroup = xcodeProj.createGroupIfNeeded(named: group, sourceRoot: sourceRoot) else {
            logger.warning("Unable to create group \(String(describing: group))")
            return
        }

        do {
            try xcodeProj.addSourceFile(at: path, toGroup: fileGroup, target: target, sourceRoot: sourceRoot)
        } catch {
            logger.warning("Failed to link file at \(path) to \(xcode.project). \(error)")
        }
    }

    func save() throws {
        try xcodeProj.writePBXProj(path: xcode.project, outputSettings: .init())
    }
}
