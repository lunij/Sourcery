import PathKit
import XCTest
import SourceryRuntime
@testable import SourceryKit

class ConfigurationReaderTests: XCTestCase {
    var sut: ConfigurationReader!

    var loggerMock: LoggerMock!

    override func setUp() {
        super.setUp()
        loggerMock = .init()
        logger = loggerMock
        sut = .init()
    }

    func test_defaultOptions() throws {
        let options = try ConfigurationOptions.parse([])
        let configurations = try sut.readConfigurations(options: options)

        XCTAssertEqual(configurations, [.init(
            sources: .paths(.init(include: [])),
            templates: .init(include: []),
            output: .init("."),
            cacheBasePath: .defaultBaseCachePath,
            forceParse: [],
            parseDocumentation: false,
            baseIndentation: 0,
            args: [:])
        ])
        XCTAssertEqual(loggerMock.calls, [.info("No config file provided or it does not exist. Using command line arguments.")])
    }
}
