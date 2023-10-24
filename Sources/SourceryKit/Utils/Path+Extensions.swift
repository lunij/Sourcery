import Foundation
import PathKit

public typealias Path = PathKit.Path

public extension Path {
    var modifiedDate: Date? {
        (try? FileManager.default.attributesOfItem(atPath: string)[.modificationDate]) as? Date
    }

    /// - returns: The `.cachesDirectory` search path in the user domain, as a `Path`.
    static var defaultBaseCachePath: Path {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
        let path = paths[0]
        return Path(path)
    }

    /// - parameter _basePath: The value of the `--cachePath` command line parameter, if any.
    /// - note: This function does not consider the `--disableCache` command line parameter.
    ///         It is considered programmer error to call this function when `--disableCache` is specified.
    static func cachesDir(sourcePath: Path, basePath _basePath: Path?, createIfMissing: Bool = true) -> Path {
        let basePath = _basePath ?? defaultBaseCachePath
        let path = basePath + "Sourcery" + sourcePath.lastComponent
        if !path.exists, createIfMissing {
            // swiftlint:disable:next force_try
            try! FileManager.default.createDirectory(at: path.url, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }

    var isTemplateFile: Bool {
        ["stencil", "swifttemplate"].contains(`extension`)
    }

    var isSwiftSourceFile: Bool {
        !isDirectory && (self.extension == "swift" || self.extension == "swiftinterface")
    }

    func hasExtension(as string: String) -> Bool {
        let extensionString = ".\(string)."
        return self.string.contains(extensionString)
    }

    init(_ string: String, relativeTo relativePath: Path) {
        var path = Path(string)
        if !path.isAbsolute {
            path = (relativePath + path).absolute()
        }
        self.init(path.string)
    }

    var allPaths: [Path] {
        if isDirectory {
            (try? recursiveChildren()) ?? []
        } else {
            [self]
        }
    }
}
