import XCTest
import SourceryRuntime
@testable import SourceryKit

class SwiftGeneratorTests: XCTestCase {
    var sut: SwiftGenerator!

    var loggerMock: LoggerMock!

    override func setUp() {
        super.setUp()
        loggerMock = .init()
        logger = loggerMock
        sut = .init()
    }

    func test_foobar() throws {
        var parsingResult: ParsingResult = (
            .stub(),
            Types(types: [], typealiases: []),
            [],
            []
        )
        try sut.generate(
            from: &parsingResult,
            using: [],
            config: .stub(sources: .paths(.init(include: [])), templates: .init(include: []), output: .init(""))
        )

        XCTAssertEqual(loggerMock.calls, [
            .info("Generating code..."),
            .benchmark("\tGeneration took 5.996227264404297e-05"),
            .info("Finished.")
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
