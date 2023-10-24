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
                    throw ConfigurationParser.Error.invalidXCFramework(message: "Framework path invalid. Expected String.")
                }
                let `extension` = Path(framework).extension
                guard `extension` == "xcframework" else {
                    throw ConfigurationParser.Error.invalidXCFramework(message: "Framework path invalid. Expected path to xcframework file.")
                }
                let moduleName = Path(framework).lastComponentWithoutExtension
                guard
                    let simulatorSlicePath = frameworkRelativePath.glob("*")
                    .first(where: { $0.lastComponent.contains("simulator") })
                else {
                    throw ConfigurationParser.Error.invalidXCFramework(path: frameworkRelativePath, message: "Framework path invalid. Expected to find simulator slice.")
                }
                let modulePath = simulatorSlicePath + Path("\(moduleName).framework/Modules/\(moduleName).swiftmodule/")
                guard let interfacePath = modulePath.glob("*.swiftinterface").first(where: { $0.lastComponent.contains("simulator") })
                else {
                    throw ConfigurationParser.Error.invalidXCFramework(path: frameworkRelativePath, message: "Framework path invalid. Expected to find .swiftinterface.")
                }
                path = frameworkRelativePath
                swiftInterfacePath = interfacePath
            }
        }

        public let name: String
        public let module: String
        public let xcframeworks: [XCFramework]
    }
}

extension Project: Equatable {
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.root == rhs.root
    }
}
