import SourceryRuntime
import XCTest
@testable import SourceryKit

class SwiftGeneratorTests: XCTestCase {
    var sut: SwiftGenerator!

    var clockMock: ClockMock!
    var loggerMock: LoggerMock!
    var xcodeProjFactoryMock: XcodeProjFactoryMock!

    override func setUp() {
        super.setUp()
        clockMock = .init()
        clockMock.measureReturnValue = .milliseconds(100)
        loggerMock = .init()
        logger = loggerMock
        xcodeProjFactoryMock = .init()
        sut = .init(clock: clockMock, xcodeProjFactory: xcodeProjFactoryMock)
    }

    func test_warnsAboutSkippedFiles() throws {
        let templateMock = TemplateMock(path: "Templates/Fake.stencil")
        templateMock.renderReturnValue = ""
        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated"))

        try sut.generate(
            from: &parsingResult,
            using: [templateMock],
            config: config
        )

        XCTAssertEqual(loggerMock.calls, [
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
            config: config
        )) { error in
            let error = error as? SwiftGenerator.Error
            XCTAssertEqual(error, .noOutput)
        }
        XCTAssertEqual(loggerMock.calls, [])
    }
}
