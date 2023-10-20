import XcodeProj

// sourcery: AutoMockable
protocol XcodeProjProtocol {
    func addGroupIfNeeded(named group: String, to parentGroup: PBXGroup, sourceRoot: Path) -> PBXGroup
    func addSourceFile(with filePath: Path, to group: PBXGroup, target: PBXTarget, sourceRoot: Path) throws
    func rootGroup() throws -> PBXGroup?
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
    func addGroupIfNeeded(named group: String, to parentGroup: PBXGroup, sourceRoot: Path) -> PBXGroup {
        var fileGroup = parentGroup
        var parentGroup = parentGroup
        let components = group.components(separatedBy: "/")

        // Find existing group to reuse
        // Having `ProjectRoot/Data/` exists and given group to create `ProjectRoot/Data/Generated`
        // will create `Generated` group under ProjectRoot/Data to link files to
        let existingGroup = findGroup(in: fileGroup, components: components)

        var groupName: String?

        switch existingGroup {
        case let (group, components) where group != nil:
            if components.isEmpty {
                // Group path is already exists
                fileGroup = group!
            } else {
                // Create rest of the group and attach to last found parent
                groupName = components.joined(separator: "/")
                parentGroup = group!
            }
        default:
            // Create new group from scratch
            groupName = group
        }

        if let groupName = groupName {
            do {
                if let addedGroup = addGroup(named: groupName, to: parentGroup),
                   let groupPath = fullPath(fileElement: addedGroup, sourceRoot: sourceRoot) {
                    fileGroup = addedGroup
                    try groupPath.mkpath()
                }
            } catch {
                logger.warning("Failed to create a folder for group '\(fileGroup.name ?? "")'. \(error)")
            }
        }
        return fileGroup
    }

    func rootGroup() throws -> PBXGroup? {
        try pbxproj.rootGroup()
    }

    func sourceFilesPaths(targetName: String, sourceRoot: Path) -> [Path] {
        guard let target = target(named: targetName) else {
            return []
        }
        return sourceFilesPaths(target: target, sourceRoot: sourceRoot)
    }

    func target(named targetName: String) -> PBXTarget? {
        pbxproj.targets(named: targetName).first
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

extension XcodeProj {
    func fullPath<E: PBXFileElement>(fileElement: E, sourceRoot: Path) -> Path? {
        try? fileElement.fullPath(sourceRoot: sourceRoot)
    }

    func sourceFilesPaths(target: PBXTarget, sourceRoot: Path) -> [Path] {
        let sourceFiles = (try? target.sourceFiles()) ?? []
        return sourceFiles
            .compactMap({ fullPath(fileElement: $0, sourceRoot: sourceRoot) })
    }

    func addGroup(named groupName: String, to toGroup: PBXGroup, options: GroupAddingOptions = []) -> PBXGroup? {
        do {
            return try toGroup.addGroup(named: groupName, options: options).last
        } catch {
            logger.error("Can't add group \(groupName) to group (uuid: \(toGroup.uuid), name: \(String(describing: toGroup.name))")
            return nil
        }
    }

    func addSourceFile(with filePath: Path, to group: PBXGroup, target: PBXTarget, sourceRoot: Path) throws {
        let fileReference = try group.addFile(at: filePath, sourceRoot: sourceRoot)
        let file = PBXBuildFile(file: fileReference, product: nil, settings: nil)

        guard let fileElement = file.file, let sourcePhase = try target.sourcesBuildPhase() else {
            throw UnableToAddSourceFile(targetName: target.name, path: filePath.string)
        }
        let buildFile = try sourcePhase.add(file: fileElement)
        pbxproj.add(object: buildFile)
    }

    func findGroup(in group: PBXGroup, components: [String]) -> (group: PBXGroup?, components: [String]) {
        let existingGroup = findGroup(in: group, components: components, validate: { $0?.path == $1 })

        if existingGroup.group?.path != nil {
            return existingGroup
        }

        return findGroup(in: group, components: components, validate: { $0?.name == $1 })
    }

    func findGroup(in group: PBXGroup, components: [String], validate: (PBXFileElement?, String?) -> Bool) -> (group: PBXGroup?, components: [String]) {
        return components.reduce((group: group as PBXGroup?, components: components)) { current, name in
            let first = current.group?.children.first { validate($0, name) } as? PBXGroup
            let result = first ?? current.group
            return (result, current.components.filter { !validate(result, $0) })
        }
    }
}

struct UnableToAddSourceFile: Error {
    var targetName: String
    var path: String
}
