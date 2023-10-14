import XCTest
@testable import SourceryKit

class SwiftTemplateParserTests: XCTestCase {
    var sut: SwiftTemplateParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_parsesControlFlowStatement() throws {
        let statements = try sut.parse(template: #"<% print("this is a control flow statement") %>"#)

        XCTAssertEqual(statements, [.controlFlow("print(\"this is a control flow statement\")")])
    }

    func test_parsesOutputStatement() throws {
        let statements = try sut.parse(template: #"<%= this is an output statement %>"#)

        XCTAssertEqual(statements, [.output("this is an output statement")])
    }

    func test_parsesIncludeStatement_whenSwiftFile() throws {
        let statements = try sut.parse(template: #"<%- include("FakeFile.swift") -%>"#)

        XCTAssertEqual(statements, [.include("FakeFile.swift", line: 1)])
    }

    func test_parsesIncludeStatement_whenSwiftTemplateFile() throws {
        let statements = try sut.parse(template: #"<%- include("FakeFile.swifttemplate") -%>"#)

        XCTAssertEqual(statements, [.include("FakeFile.swifttemplate", line: 1)])
    }

    func test_parsesIncludeStatement_whenMultiple() throws {
        let statements = try sut.parse(template: #"""
        <%- include("FakeFile1.swifttemplate") -%>
        <%- include("FakeFile2.swifttemplate") -%>
        """#)

        XCTAssertEqual(statements, [
            .include("FakeFile1.swifttemplate", line: 1),
            .include("FakeFile2.swifttemplate", line: 2)
        ])
    }

    func test_failsParsingIncludeStatement_whenInvalidSyntax() throws {
        XCTAssertThrowsError(try sut.parse(template: #"<%- include "FakeFile.swifttemplate" -%>"#)) { error in
            let error = error as? SwiftTemplateParser.ParsingError
            XCTAssertEqual(error, .invalidIncludeStatement(line: 1))
        }
    }

    func test_failsParsingIncludeStatement_whenMissingFileExtension() throws {
        XCTAssertThrowsError(try sut.parse(template: #"<%- include("FakeFile") -%>"#)) { error in
            let error = error as? SwiftTemplateParser.ParsingError
            XCTAssertEqual(error, .missingFileExtension(line: 1))
        }
    }

    func test_failsParsingIncludeStatement_whenUnsupportedFileExtension() {
        XCTAssertThrowsError(try sut.parse(template: #"<%- include("FakeFile.cpp") -%>"#)) { error in
            let error = error as? SwiftTemplateParser.ParsingError
            XCTAssertEqual(error, .unsupportedFileExtension(line: 1))
        }
    }

    func test_parsesMultipleStatements() throws {
        let statements = try sut.parse(template: """
        <% for type in types.all { %>
        // <%= type.name %>
        <% } %>
        """)

        XCTAssertEqual(statements, [
            .controlFlow("for type in types.all {"),
            .outputEncoded("\n// "),
            .output("type.name"),
            .outputEncoded("\n"),
            .controlFlow("}")
        ])
    }
}
