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

    func test_loadsTemplates_whenNothingToLoad() throws {
        XCTAssertNoThrow(try sut.loadTemplates(from: .stub(cacheDisabled: true), buildPath: nil))
        XCTAssertEqual(loggerMock.calls, [
            .info("Loaded 0 templates in 0.1 seconds")
        ])
    }

    func test_loadsTemplates_whenTemplatesPaths() throws {
        let templates = try sut.loadTemplates(from: .stub(templates: [Stubs.templateDirectory], cacheDisabled: true), buildPath: nil)
        let templatesPath = Stubs.templateDirectory.relativeToCurrent
        XCTAssertEqual(templates.count, 5)
        XCTAssertEqual(loggerMock.calls, [
            .info("Loading \(templatesPath)/Basic.stencil"),
            .info("Loading \(templatesPath)/Other.stencil"),
            .info("Loading \(templatesPath)/GenerationWays.stencil"),
            .info("Loading \(templatesPath)/Partial.stencil"),
            .info("Loading \(templatesPath)/Include.stencil"),
            .info("Loaded 5 templates in 0.1 seconds")
        ])
    }
}
