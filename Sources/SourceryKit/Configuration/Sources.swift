public enum Sources {
    case paths(Paths)
    case projects([Project])

    public var isEmpty: Bool {
        switch self {
        case let .paths(paths):
            return paths.allPaths.isEmpty
        case let .projects(projects):
            return projects.isEmpty
        }
    }
}

extension Sources: Equatable {
    public static func == (lhs: Sources, rhs: Sources) -> Bool {
        switch (lhs, rhs) {
        case let (.paths(lhs), .paths(rhs)):
            return lhs == rhs
        case let (.projects(lhs), .projects(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
