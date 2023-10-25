import PathKit
import SourceryRuntime
import XCTest
@testable import SourceryKit

class ConfigurationReaderTests: XCTestCase {
    var sut: ConfigurationReader!

    var loggerMock: LoggerMock!
    var parserMock: ConfigurationParserMock!

    override func setUp() {
        super.setUp()
        loggerMock = .init()
        logger = loggerMock
        parserMock = .init()
        sut = .init(parser: parserMock)
    }

    func test_defaultOptions() throws {
        let options = try ConfigurationOptions.parse([])
        let configurations = try sut.readConfigurations(options: options)

        XCTAssertEqual(configurations, [
            .init(
                sources: .paths(.init(include: [])),
                templates: .init(include: []),
                output: .init("."),
                cacheBasePath: .defaultBaseCachePath,
                cacheDisabled: false,
                forceParse: [],
                parseDocumentation: false,
                baseIndentation: 0,
                arguments: [:]
            )
        ])
        XCTAssertEqual(loggerMock.calls, [.info("No config file provided or it does not exist. Using command line arguments.")])
        XCTAssertEqual(parserMock.calls, [])
    }
}
