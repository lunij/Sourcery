import XcodeProj

public struct Output: Equatable {
    public struct LinkTo: Equatable {
        public let project: XcodeProj
        public let projectPath: Path
        public let targets: [String]
        public let group: String?
    }

    public let path: Path
    public let link: LinkTo?

    public var isRepresentingDirectory: Bool {
        isNotEmpty && (path.lastComponentWithoutExtension == path.lastComponent || path.string.hasSuffix("/"))
    }

    public var isEmpty: Bool {
        path.string.isEmpty
    }

    public var isNotEmpty: Bool {
        path.string.isNotEmpty
    }

    public init(_ path: Path, link: LinkTo? = nil) {
        self.path = path
        self.link = link
    }
}
