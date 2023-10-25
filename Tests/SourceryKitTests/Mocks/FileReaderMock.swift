@testable import SourceryKit

class FileReaderMock: FileReading {
    enum Call: Equatable {
        case read(Path, String.Encoding)
    }

    var calls: [Call] = []

    var readError: Error?
    var readReturnValue: String?
    func read(from path: Path, encoding: String.Encoding) throws -> String {
        calls.append(.read(path, encoding))
        if let readError { throw readError }
        if let readReturnValue { return readReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
