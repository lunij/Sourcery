import XCTest
import SourceryRuntime
@testable import SourceryKit

class SwiftGeneratorTests: XCTestCase {
    var sut: SwiftGenerator!

    var clockMock: ClockMock!
    var loggerMock: LoggerMock!

    override func setUp() {
        super.setUp()
        clockMock = .init()
        loggerMock = .init()
        logger = loggerMock
        sut = .init(clock: clockMock)
    }

    func test_foobar() throws {
        clockMock.measureReturnValue = .milliseconds(100)
        var parsingResult = ParsingResult.stub()
        try sut.generate(
            from: &parsingResult,
            using: [],
            config: .stub()
        )

        XCTAssertEqual(loggerMock.calls, [
            .info("Generating code..."),
            .info("Code generation finished in 0.1 seconds")
        ])
    }
}
