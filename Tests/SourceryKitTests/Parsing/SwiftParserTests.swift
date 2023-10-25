import PathKit
import SourceryRuntime
import XCTest
@testable import SourceryKit

class SwiftParserTests: XCTestCase {
    var sut: SwiftParser!

    var output: Output!

    var loggerMock: LoggerMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        loggerMock = .init()
        logger = loggerMock
        output = try .init(.createTestDirectory(suffixed: "SwiftParserTests"))
        sut = .init()
    }

    func test_foobar() throws {
        let parsingResult = try sut.parseSources(from: .stub(), serialParse: false, cacheDisabled: false)

        XCTAssertEqual(parsingResult.parserResult, nil)
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(types: [], typealiases: []))
        XCTAssertTrue(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [
            .info("Found 0 types in 0 files, 0 changed from last run.")
        ])
    }

    func test_failsParsing_whenContainingMergeConflictMarkers() {
        let sourcePath = output.path + Path("Source.swift")

        """


        <<<<<

        """.update(in: sourcePath)

        XCTAssertThrowsError(try sut.parseSources(
            from: .stub(
                sources: .paths(Paths(include: [sourcePath])),
                templates: Paths(include: [.basicStencilPath]),
                output: output
            ),
            serialParse: false,
            cacheDisabled: false
        )) {
            let error = $0 as? SwiftParser.Error
            XCTAssertEqual(error, .containsMergeConflictMarkers)
        }
    }
}

private extension Path {
    static let basicStencilPath = Stubs.templateDirectory + Path("Basic.stencil")
}

private extension String {
    func update(in path: Path, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try path.write(self)
        } catch {
            XCTFail(String(describing: error), file: file, line: line)
        }
    }
}
