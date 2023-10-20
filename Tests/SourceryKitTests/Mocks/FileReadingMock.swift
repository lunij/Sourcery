// Generated using Sourcery

class FileReadingMock: FileReading {




    // MARK: - read

    var readFromEncodingThrowableError: Error?
    var readFromEncodingCallsCount = 0
    var readFromEncodingCalled: Bool {
        return readFromEncodingCallsCount > 0
    }
    var readFromEncodingReceivedArguments: (path: Path, encoding: String.Encoding)?
    var readFromEncodingReceivedInvocations: [(path: Path, encoding: String.Encoding)] = []
    var readFromEncodingReturnValue: String!
    var readFromEncodingClosure: ((Path, String.Encoding) throws -> String)?

    func read(from path: Path, encoding: String.Encoding) throws -> String {
        if let error = readFromEncodingThrowableError {
            throw error
        }
        readFromEncodingCallsCount += 1
        readFromEncodingReceivedArguments = (path: path, encoding: encoding)
        readFromEncodingReceivedInvocations.append((path: path, encoding: encoding))
        if let readFromEncodingClosure = readFromEncodingClosure {
            return try readFromEncodingClosure(path, encoding)
        } else {
            return readFromEncodingReturnValue
        }
    }

}
