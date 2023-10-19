import XCTest
@testable import SourceryKit

class SourceryCommandTests: XCTestCase {
    var sut: SourceryCommand!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_failsRunning_whenDryWatchIncompatibility() async throws {
        do {
            try await SourceryCommand.parse(["--dry", "--watch"]).run()
            XCTFail("Call is expected to throw")
        } catch let error as SourceryCommand.Error {
            XCTAssertEqual(error, .dryWatchIncompatibility)
            XCTAssertEqual(error.description, "--dry not compatible with --watch")
        }
    }
}
