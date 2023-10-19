public enum Sources {
    case paths(Paths)
    case projects([Project])

    public init(dict: [String: Any], relativePath: Path) throws {
        if let projects = (dict["project"] as? [[String: Any]]) ?? (dict["project"] as? [String: Any]).map({ [$0] }) {
            guard !projects.isEmpty else { throw ConfigurationParser.Error.invalidSources(message: "No projects provided.") }
            self = try .projects(projects.map({ try Project(dict: $0, relativePath: relativePath) }))
        } else if let sources = dict["sources"] {
            do {
                self = try .paths(Paths(dict: sources, relativePath: relativePath))
            } catch {
                throw ConfigurationParser.Error.invalidSources(message: "\(error)")
            }
        } else {
            throw ConfigurationParser.Error.invalidSources(message: "'sources' or 'project' key are missing.")
        }
    }

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
