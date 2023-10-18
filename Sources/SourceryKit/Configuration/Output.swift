import SourceryRuntime
import XcodeProj

public struct Output: Equatable {
    public struct LinkTo: Equatable {
        public let project: XcodeProj
        public let projectPath: Path
        public let targets: [String]
        public let group: String?

        public init(dict: [String: Any], relativePath: Path) throws {
            guard let project = dict["project"] as? String else {
                throw Configuration.Error.invalidOutput(message: "No project file path provided.")
            }
            if let target = dict["target"] as? String {
                self.targets = [target]
            } else if let targets = dict["targets"] as? [String] {
                self.targets = targets
            } else {
                throw Configuration.Error.invalidOutput(message: "No target(s) provided.")
            }
            let projectPath = Path(project, relativeTo: relativePath)
            self.projectPath = projectPath
            self.project = try XcodeProj(path: projectPath)
            self.group = dict["group"] as? String
        }
    }

    public let path: Path
    public let linkTo: LinkTo?

    public var isDirectory: Bool {
        guard path.exists else {
            return path.lastComponentWithoutExtension == path.lastComponent || path.string.hasSuffix("/")
        }
        return path.isDirectory
    }

    public init(dict: [String: Any], relativePath: Path) throws {
        guard let path = dict["path"] as? String else {
            throw Configuration.Error.invalidOutput(message: "No path provided.")
        }

        self.path = Path(path, relativeTo: relativePath)

        if let linkToDict = dict["link"] as? [String: Any] {
            do {
                self.linkTo = try LinkTo(dict: linkToDict, relativePath: relativePath)
            } catch {
                self.linkTo = nil
                logger.warning(error)
            }
        } else {
            self.linkTo = nil
        }
    }

    public init(_ path: Path, linkTo: LinkTo? = nil) {
        self.path = path
        self.linkTo = linkTo
    }
}
