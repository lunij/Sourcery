import SourceryRuntime
import XCTest
@testable import SourceryKit

class SwiftGeneratorTests: XCTestCase {
    var sut: SwiftGenerator!

    var clockMock: ClockMock!
    var loggerMock: LoggerMock!
    var blockAnnotationParserMock: BlockAnnotationParserMock!
    var xcodeProjModifierMock: XcodeProjModifierMock!
    var xcodeProjModifierFactoryMock: XcodeProjModifierFactoryMock!

    override func setUp() {
        super.setUp()
        clockMock = .init()
        clockMock.measureReturnValue = .milliseconds(100)
        loggerMock = .init()
        logger = loggerMock
        blockAnnotationParserMock = .init()
        xcodeProjModifierMock = .init()
        xcodeProjModifierFactoryMock = .init()
        xcodeProjModifierFactoryMock.makeModifierReturnValue = xcodeProjModifierMock
        sut = .init(
            clock: clockMock,
            blockAnnotationParser: blockAnnotationParserMock,
            xcodeProjModifierFactory: xcodeProjModifierFactoryMock
        )
    }

    func test_warnsAboutSkippedFiles() throws {
        let templateMock = TemplateMock(path: "Templates/Fake.stencil")
        templateMock.renderReturnValue = ""
        blockAnnotationParserMock.parseAnnotationsReturnValue = .init()
        blockAnnotationParserMock.annotationRangesReturnValue = (annotations: .init(), rangesToReplace: [])
        blockAnnotationParserMock.removingEmptyAnnotationsReturnValue = ""

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
        XCTAssertEqual(blockAnnotationParserMock.calls, [
            .parseAnnotations,
            .annotationRanges,
            .removingEmptyAnnotations
        ])
    }

    func test_warnsAboutSingleFileOutput() throws {
        let templateMock = TemplateMock()
        templateMock.renderReturnValue = ""
        blockAnnotationParserMock.parseAnnotationsReturnValue = .init()
        blockAnnotationParserMock.annotationRangesReturnValue = (annotations: .init(), rangesToReplace: [])
        blockAnnotationParserMock.removingEmptyAnnotationsReturnValue = ""

        var parsingResult = ParsingResult.stub()
        let config = Configuration.stub(output: .init("Generated/SingleOutput.generated.swift"))

        try sut.generate(
            from: &parsingResult,
            using: [templateMock],
            config: config
        )

        XCTAssertEqual(loggerMock.calls.first, .warning("The output path targets a single file. Continuing using its directory instead."))
        XCTAssertEqual(blockAnnotationParserMock.calls, [
            .parseAnnotations,
            .annotationRanges,
            .removingEmptyAnnotations
        ])
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
