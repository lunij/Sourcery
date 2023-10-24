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

    func test_warnsAboutSkippedFiles() throws {
        let templateMock = TemplateMock(path: "Templates/Fake.stencil")
        templateMock.renderReturnValue = ""
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated"))

        try sut.generate(
            from: &parsingResult,
            using: [templateMock],
            to: config.output,
            config: config
        )

        XCTAssertEqual(loggerMock.calls, [
            .info("Generating code..."),
            .warning("Skipping Generated/Fake.generated.swift as its generated content is empty."),
            .info("Code generation finished in 0.1 seconds")
        ])
        XCTAssertEqual(templateMock.calls, [.render])
    }

    func test_warnsAboutSingleFileOutput() throws {
        let templateMock = TemplateMock()
        templateMock.renderReturnValue = ""
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated/SingleOutput.generated.swift"))

        try sut.generate(
            from: &parsingResult,
            using: [templateMock],
            to: config.output,
            config: config
        )

        XCTAssertEqual(loggerMock.calls.first, .warning("The output path targets a single file. Continuing using its directory instead."))
    }

    func test_failsGenerating_whenNoTemplates() throws {
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated"))

        XCTAssertThrowsError(try sut.generate(
            from: &parsingResult,
            using: [],
            to: config.output,
            config: config
        )) { error in
            let error = error as? SwiftGenerator.Error
            XCTAssertEqual(error, .noTemplates)
        }
        XCTAssertEqual(loggerMock.calls, [])
    }

    func test_failsGenerating_whenNoOutput() throws {
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init(""))

        XCTAssertThrowsError(try sut.generate(
            from: &parsingResult,
            using: [],
            to: config.output,
            config: config
        )) { error in
            let error = error as? SwiftGenerator.Error
            XCTAssertEqual(error, .noOutput)
        }
        XCTAssertEqual(loggerMock.calls, [])
    }
}
