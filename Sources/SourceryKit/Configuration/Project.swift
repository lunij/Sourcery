import SourceryRuntime
import XcodeProj

public struct Project: Equatable {
    public let path: Path
    public let targets: [Target]
    public let exclude: [Path]

    public struct Target: Equatable {
        public let name: String
        public let module: String
        public let xcframeworks: [XCFramework]

        public struct XCFramework: Equatable {
            public let path: Path
            public let swiftInterfacePath: Path
        }
    }
}

extension Project {
    var root: Path {
        path.parent()
    }
}
