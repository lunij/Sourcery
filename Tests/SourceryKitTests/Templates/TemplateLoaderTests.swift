import SourceryRuntime
import XCTest
@testable import SourceryKit

class TemplateLoaderTests: XCTestCase {
    var sut: TemplateLoader!

    var clockMock: ClockMock!
    var loggerMock: LoggerMock!

    override func setUp() {
        super.setUp()
        clockMock = .init()
        clockMock.measureReturnValue = .milliseconds(100)
        loggerMock = .init()
        logger = loggerMock
        sut = .init(clock: clockMock)
    }

    func test_foobar() throws {
        XCTAssertNoThrow(try sut.loadTemplates(from: .stub(cacheDisabled: true), buildPath: nil))
        XCTAssertEqual(loggerMock.calls, [
            .info("Loaded 0 templates in 0.1 seconds")
        ])
    }
}
