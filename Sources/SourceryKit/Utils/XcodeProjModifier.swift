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
    func addSourceFile(path: Path) throws
    func save() throws
}

class XcodeProjModifier: XcodeProjModifying {
    let xcode: Xcode
    let xcodeProj: XcodeProjProtocol

    init(xcode: Xcode, xcodeProj: XcodeProjProtocol) {
        self.xcode = xcode
        self.xcodeProj = xcodeProj
    }

    func addSourceFile(path: Path) throws {
        for target in xcode.targets {
            try addSourceFile(at: path, target: target, group: xcode.group)
        }
    }

    private func addSourceFile(at path: Path, target: String, group groupName: String?) throws {
        guard let target = xcodeProj.target(named: target) else {
            throw Error.targetNotFound(name: target)
        }

        let sourceRoot = xcode.project.parent()

        guard let rootGroup = try xcodeProj.rootGroup() else {
            throw Error.malformedXcodeProject(context: "Root group not found.")
        }

        var group = rootGroup
        if let groupName {
            group = xcodeProj.addGroupIfNeeded(named: groupName, to: rootGroup, sourceRoot: sourceRoot)
        }

        do {
            try xcodeProj.addSourceFile(with: path, to: group, target: target, sourceRoot: sourceRoot)
        } catch {
            throw Error.failedToAddSourceFile(path, group: group.name, target: target.name, projectPath: xcode.project, context: String(describing: error))
        }
    }

    func save() throws {
        try xcodeProj.writePBXProj(path: xcode.project, outputSettings: .init())
    }

    enum Error: Swift.Error, Equatable {
        case failedToAddSourceFile(Path, group: String?, target: String, projectPath: Path, context: String)
        case malformedXcodeProject(context: String)
        case targetNotFound(name: String)
    }
}
