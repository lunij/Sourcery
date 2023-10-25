import Foundation

protocol FileReading {
    func read(from path: Path, encoding: String.Encoding) throws -> String
}

extension FileReading {
    func read(from path: Path) throws -> String {
        try read(from: path, encoding: .utf8)
    }
}

class FileReader: FileReading {
    func read(from path: Path, encoding: String.Encoding) throws -> String {
        do {
            return try path.read(encoding)
        } catch {
            throw Error.bridged(from: error, with: path)
        }
    }

    enum Error: Swift.Error, Equatable {
        case fileIsADirectory(Path)
        case fileNotExisting(Path)
        case fileNotReadable(Path)
    }
}

private extension FileReader.Error {
    static func bridged(from error: Swift.Error, with path: Path) -> any Error {
        let error = error as NSError
        switch (error.domain, error.code) {
        case ("NSCocoaErrorDomain", 256):
            return Self.fileIsADirectory(path)
        case ("NSCocoaErrorDomain", 257):
            return Self.fileNotReadable(path)
        case ("NSCocoaErrorDomain", 260):
            return Self.fileNotExisting(path)
        default:
            return error
        }
    }
}
