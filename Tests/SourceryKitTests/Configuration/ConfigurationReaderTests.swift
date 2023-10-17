import PathKit
import XCTest
@testable import SourceryKit

class ConfigurationReaderTests: XCTestCase {
    var sut: ConfigurationReader!

    override func setUp() {
        super.setUp()
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
    }
}
