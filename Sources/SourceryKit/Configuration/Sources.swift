public enum Sources {
    case paths(Paths)
    case projects([Project])

    public var isEmpty: Bool {
        switch self {
        case let .paths(paths):
            paths.blendedPaths.isEmpty
        case let .projects(projects):
            projects.isEmpty
        }
    }
}

extension Sources: Equatable {
    public static func == (lhs: Sources, rhs: Sources) -> Bool {
        switch (lhs, rhs) {
        case let (.paths(lhs), .paths(rhs)):
            lhs == rhs
        case let (.projects(lhs), .projects(rhs)):
            lhs == rhs
        default:
            false
        }
    }
}
