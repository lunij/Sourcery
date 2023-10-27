import class Foundation.FileManager
import PathKit

extension Path {
    public static var systemCachePath: Path {
        do {
            let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return Path(url.path)
        } catch {
            fatalError(String(describing: error))
        }
    }

    var generatedFileName: String {
        "\(lastComponentWithoutExtension).generated.swift"
    }

    var hasExtension: Bool {
        url.pathExtension.isNotEmpty
    }

    var isRepresentingDirectory: Bool {
        string.isNotEmpty && (!hasExtension || string.hasSuffix("/"))
    }

    var relativeToCurrent: Path {
        Path(string.replacingOccurrences(of: Path.current.string + "/", with: ""))
    }

    var unlinked: Path {
        (try? symlinkDestination()) ?? self
    }

    func appending(_ path: String) -> Path {
        self + Path(path)
    }
}

// MARK: - FileWritable

protocol FileWritable {
    func write(_ string: String, encoding: String.Encoding) throws
    func writeIfChanged(_ newContent: String) throws
}

extension FileWritable {
    func write(_ string: String) throws {
        try write(string, encoding: .utf8)
    }
}

extension Path: FileWritable {
    func writeIfChanged(_ newContent: String) throws {
        guard exists else {
            return try write(newContent)
        }

        let currentContent = try read(.utf8)
        if currentContent != newContent {
            try write(newContent)
        }
    }
}
