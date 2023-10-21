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
        var parsingResult = ParsingResult(
            parserResult: .stub(),
            types: Types(types: [], typealiases: []),
            functions: [],
            inlineRanges: []
        )
        try sut.generate(
            from: &parsingResult,
            using: [],
            config: .stub(sources: .paths(.init(include: [])), templates: .init(include: []), output: .init(""))
        )

        XCTAssertEqual(loggerMock.calls, [
            .info("Generating code..."),
            .info("Code generation finished in 0.1 seconds")
        ])
    }
}

private extension FileParserResult {
    static func stub(
        path: String? = nil,
        module: String? = nil,
        types: [Type] = [],
        functions: [SourceryMethod] = [],
        typealiases: [Typealias] = [],
        inlineRanges: [String: NSRange] = [:],
        inlineIndentations: [String: String] = [:],
        modifiedDate: Date = .now,
        sourceryVersion: String = "fakeVersion"
    ) -> Self {
        .init(
            path: path,
            module: module,
            types: types,
            functions: functions,
            typealiases: typealiases,
            inlineRanges: inlineRanges,
            inlineIndentations: inlineIndentations,
            modifiedDate: modifiedDate,
            sourceryVersion: sourceryVersion
        )
    }
}
