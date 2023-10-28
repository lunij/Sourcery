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

    func test_loadsTemplates_whenNothingToLoad() throws {
        XCTAssertNoThrow(try sut.loadTemplates(from: .stub(cacheDisabled: true), buildPath: nil))
        XCTAssertEqual(loggerMock.calls, [
            .info("Loaded 0 templates in 0.1 seconds")
        ])
    }

    func test_loadsTemplates_whenTemplatesPaths() throws {
        let templates = try sut.loadTemplates(from: .stub(templates: [Stubs.templateDirectory], cacheDisabled: true), buildPath: nil)
        XCTAssertEqual(templates.count, 5)
        XCTAssertEqual(loggerMock.calls, [
            .info("Loading \(Stubs.templateDirectory)/Basic.stencil"),
            .info("Loading \(Stubs.templateDirectory)/Other.stencil"),
            .info("Loading \(Stubs.templateDirectory)/GenerationWays.stencil"),
            .info("Loading \(Stubs.templateDirectory)/Partial.stencil"),
            .info("Loading \(Stubs.templateDirectory)/Include.stencil"),
            .info("Loaded 5 templates in 0.1 seconds")
        ])
    }
}
