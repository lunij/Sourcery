import PathKit
import XCTest
@testable import SourceryKit

class FileReaderTests: XCTestCase {
    var sut: FileReader!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_readsFile() throws {
        let fileContent = try sut.read(from: #file)

        XCTAssertTrue(fileContent.contains("class FileReaderTests: XCTestCase"))
    }

    func test_failsReadingFile_whenFileNotExisting() {
        XCTAssertThrowsError(try sut.read(from: "not-existing-file")) { error in
            let error = error as? FileReader.Error
            XCTAssertEqual(error, .fileNotExisting("not-existing-file"))
        }
    }

    func test_failsReadingFile_whenFileNotReadable() throws {
        let notReadableFile = Path.bundleResourcePath.appending("Fixtures/not-readable-file")
        try notReadableFile.setPosixPermissions(to: 0o000)
        XCTAssertThrowsError(try sut.read(from: notReadableFile)) { error in
            let error = error as? FileReader.Error
            XCTAssertEqual(error, .fileNotReadable(notReadableFile))
        }
    }

    func test_failsReadingFile_whenFileIsADirectory() {
        let notAFile = Path.bundleResourcePath.appending("Fixtures/not-a-file")
        XCTAssertThrowsError(try sut.read(from: notAFile)) { error in
            let error = error as? FileReader.Error
            XCTAssertEqual(error, .fileIsADirectory(notAFile))
        }
    }
}

private extension Path {
    static var bundleResourcePath = Path(Bundle.module.resourcePath!)

    func setPosixPermissions(to number: NSNumber) throws {
        try FileManager.default.setAttributes([.posixPermissions: number], ofItemAtPath: string)
    }
}
