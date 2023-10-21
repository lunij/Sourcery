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
        clockMock.measureReturnValue = .milliseconds(100)
        loggerMock = .init()
        logger = loggerMock
        sut = .init(clock: clockMock)
    }

    func test_foobar() throws {
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated"))

        try sut.generate(
            from: &parsingResult,
            using: [],
            to: config.output,
            config: config
        )

        XCTAssertEqual(loggerMock.calls, [
            .info("Generating code..."),
            .info("Code generation finished in 0.1 seconds")
        ])
    }

    func test_failsGenerating_whenUndefinedOutput() throws {
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init(""))

        XCTAssertThrowsError(try sut.generate(
            from: &parsingResult,
            using: [],
            to: config.output,
            config: config
        )) { error in
            let error = error as? SwiftGenerator.Error
            XCTAssertEqual(error, .undefinedOutput)
        }
        XCTAssertEqual(loggerMock.calls, [])
    }
}
