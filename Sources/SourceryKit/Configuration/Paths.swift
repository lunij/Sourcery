import Foundation
import PathKit

public struct Paths: Equatable {
    public let include: [Path]
    public let exclude: [Path]
    public let allPaths: [Path]

    public var isEmpty: Bool {
        allPaths.isEmpty
    }

    public init(include: [Path], exclude: [Path] = []) {
        self.include = include
        self.exclude = exclude

        let include = self.include.parallelFlatMap { $0.processablePaths }
        let exclude = self.exclude.parallelFlatMap { $0.processablePaths }

        allPaths = Array(Set(include).subtracting(Set(exclude))).sorted()
    }
}

private extension Path {
    var processablePaths: [Path] {
        if isDirectory {
            (try? recursiveUnhiddenChildren()) ?? []
        } else {
            [self]
        }
    }

    func recursiveUnhiddenChildren() throws -> [Path] {
        FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.pathKey], options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: nil)?.compactMap { object in
            if let url = object as? URL {
                return self + Path(url.path)
            }
            return nil
        } ?? []
    }
}
