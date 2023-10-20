import XcodeProj

public struct Output: Equatable {
    public struct LinkTo: Equatable {
        public let project: XcodeProj
        public let projectPath: Path
        public let targets: [String]
        public let group: String?
    }

    public let path: Path
    public let linkTo: LinkTo?

    public var isDirectory: Bool {
        guard path.exists else {
            return path.lastComponentWithoutExtension == path.lastComponent || path.string.hasSuffix("/")
        }
        return path.isDirectory
    }

    public init(_ path: Path, linkTo: LinkTo? = nil) {
        self.path = path
        self.linkTo = linkTo
    }
}
