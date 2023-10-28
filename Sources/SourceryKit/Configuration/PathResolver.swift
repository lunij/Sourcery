import Foundation
import PathKit

protocol PathResolving {
    func resolve(includes: [Path], excludes: [Path]) -> [Path]
}

class PathResolver: PathResolving {
    func resolve(includes: [Path], excludes: [Path]) -> [Path] {
        let include = includes.parallelFlatMap { $0.processablePaths }
        let exclude = excludes.parallelFlatMap { $0.processablePaths }

        return Array(Set(include).subtracting(Set(exclude))).sorted()
    }
}

private extension Path {
    var isHidden: Bool {
        string.hasPrefix(".")
    }

    var processablePaths: [Path] {
        if isDirectory {
            let children = (try? children()) ?? []
            return children.filter { !$0.isHidden }
        } else {
            return [self]
        }
    }
}
