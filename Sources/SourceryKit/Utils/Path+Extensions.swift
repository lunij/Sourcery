import Foundation
import PathKit

public typealias Path = PathKit.Path

extension Path {
    /// - parameter _basePath: The value of the `--cachePath` command line parameter, if any.
    /// - note: This function does not consider the `--disableCache` command line parameter.
    ///         It is considered programmer error to call this function when `--disableCache` is specified.
    public static func cachesDir(sourcePath: Path, basePath _basePath: Path?, createIfMissing: Bool = true) -> Path {
        let basePath = _basePath ?? .systemCachePath
        let path = basePath + "Sourcery" + sourcePath.lastComponent
        if !path.exists && createIfMissing {
            // swiftlint:disable:next force_try
            try! FileManager.default.createDirectory(at: path.url, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }

    public var isTemplateFile: Bool {
        `extension` == "stencil"
    }

    public var isSwiftSourceFile: Bool {
        return !self.isDirectory && (self.extension == "swift" || self.extension == "swiftinterface")
    }

    public func hasExtension(as string: String) -> Bool {
        let extensionString = ".\(string)."
        return self.string.contains(extensionString)
    }

    public init(_ string: String, relativeTo relativePath: Path) {
        var path = Path(string)
        if !path.isAbsolute {
            path = (relativePath + path).absolute()
        }
        self.init(path.string)
    }

    public var allPaths: [Path] {
        if isDirectory {
            return (try? recursiveChildren()) ?? []
        } else {
            return [self]
        }
    }

}
