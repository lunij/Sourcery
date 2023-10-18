import PathKit
import SourceryRuntime
import XcodeProj

public struct Project {
    public let file: XcodeProj
    public let root: Path
    public let targets: [Target]
    public let exclude: [Path]

    public struct Target {

        public struct XCFramework {

            public let path: Path
            public let swiftInterfacePath: Path

            public init(rawPath: String, relativePath: Path) throws {
                let frameworkRelativePath = Path(rawPath, relativeTo: relativePath)
                guard let framework = frameworkRelativePath.components.last else {
                    throw Configuration.Error.invalidXCFramework(message: "Framework path invalid. Expected String.")
                }
                let `extension` = Path(framework).`extension`
                guard `extension` == "xcframework" else {
                    throw Configuration.Error.invalidXCFramework(message: "Framework path invalid. Expected path to xcframework file.")
                }
                let moduleName = Path(framework).lastComponentWithoutExtension
                guard
                    let simulatorSlicePath = frameworkRelativePath.glob("*")
                        .first(where: { $0.lastComponent.contains("simulator") })
                else {
                    throw Configuration.Error.invalidXCFramework(path: frameworkRelativePath, message: "Framework path invalid. Expected to find simulator slice.")
                }
                let modulePath = simulatorSlicePath + Path("\(moduleName).framework/Modules/\(moduleName).swiftmodule/")
                guard let interfacePath = modulePath.glob("*.swiftinterface").first(where: { $0.lastComponent.contains("simulator") })
                else {
                    throw Configuration.Error.invalidXCFramework(path: frameworkRelativePath, message: "Framework path invalid. Expected to find .swiftinterface.")
                }
                self.path = frameworkRelativePath
                self.swiftInterfacePath = interfacePath
            }
        }

        public let name: String
        public let module: String
        public let xcframeworks: [XCFramework]

        public init(dict: [String: Any], relativePath: Path) throws {
            guard let name = dict["name"] as? String else {
                throw Configuration.Error.invalidSources(message: "Target name is not provided. Expected string.")
            }
            self.name = name
            self.module = (dict["module"] as? String) ?? name
            do {
                self.xcframeworks = try (dict["xcframeworks"] as? [String])?
                    .map { try XCFramework(rawPath: $0, relativePath: relativePath) } ?? []
            } catch let error as Configuration.Error {
                logger.warning(error.description)
                self.xcframeworks = []
            }
        }
    }

    public init(dict: [String: Any], relativePath: Path) throws {
        guard let file = dict["file"] as? String else {
            throw Configuration.Error.invalidSources(message: "Project file path is not provided. Expected string.")
        }

        let targetsArray: [Target]
        if let targets = dict["target"] as? [[String: Any]] {
            targetsArray = try targets.map({ try Target(dict: $0, relativePath: relativePath) })
        } else if let target = dict["target"] as? [String: Any] {
            targetsArray = try [Target(dict: target, relativePath: relativePath)]
        } else {
            throw Configuration.Error.invalidSources(message: "'target' key is missing. Expected object or array of objects.")
        }
        guard !targetsArray.isEmpty else {
            throw Configuration.Error.invalidSources(message: "No targets provided.")
        }
        self.targets = targetsArray

        let exclude = (dict["exclude"] as? [String])?.map({ Path($0, relativeTo: relativePath) }) ?? []
        self.exclude = exclude.flatMap { $0.allPaths }

        let path = Path(file, relativeTo: relativePath)
        self.file = try XcodeProj(path: path)
        self.root = path.parent()
    }

}

extension Project: Equatable {
    public static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.root == rhs.root
    }
}
