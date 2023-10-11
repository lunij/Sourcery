import Foundation
import os.log
import XCTest

final class TestHelper {
    static let fileManager = FileManager.default
    static let testDirectory: URL = {
        let url = fileManager.temporaryDirectory.appendingPathComponent("test-FileSystemEvents")
        os_log("%{PUBLIC}@", "TEST DIRECTORY \(url)")
        return url
    }()

    private let name: String
    private var createdDirectories: Set<URL> = []
    private var fileManager: FileManager { Self.fileManager }
    private var testDirectory: URL { Self.testDirectory }

    init(name: String) {
        self.name = name
    }

    func createTestDirectory(suffixed suffix: String = #function) throws -> URL {
        let url = testDirectory.appending(path: "\(name).\(suffix)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: url, removeExisting: true)
        createdDirectories.insert(url)
        return url
    }

    func deleteCreatedDirectories() {
        for url in createdDirectories {
            try? fileManager.removeItem(at: url)
        }
    }
}

private extension FileManager {
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool = true,
        removeExisting: Bool = false
    ) throws {
        if removeExisting, fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
        try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
    }
}

extension URL {
    @discardableResult
    func createFile(with content: String, using encoding: String.Encoding = .utf8) -> Self {
        createFile(data: content.data(using: encoding))
        return self
    }

    @discardableResult
    func createFile(data: Data? = nil) -> Self {
        FileManager.default.createFile(atPath: path, contents: data)
        return self
    }

    func delete() throws {
        try FileManager.default.removeItem(at: self)
    }
}

func assert<O: OptionSet>(_ optionSet: O, toContain element: O.Element, file: StaticString = #filePath, line: UInt = #line) {
    if optionSet.contains(element) { return }
    XCTFail("'\(element)' is not contained in '\(optionSet)'", file: file, line: line)
}

func assert(_ string: String, toContain subString: String, file: StaticString = #filePath, line: UInt = #line) {
    if string.contains(subString) { return }
    XCTFail("'\(subString)' is not contained in '\(string)'", file: file, line: line)
}
