import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class TemplateAnnotationParserTests: XCTestCase {
    var sut: TemplateAnnotationParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_regex_1() throws {
        let source = """
        ignored
        // sourcery:inline:Type.AutoCoding
        var something: Int
        // sourcery:end
        ignored
        """
        let match = try XCTUnwrap(try sut.regex.firstMatch(in: source))
        XCTAssertEqual(match.output.0, """
        // sourcery:inline:Type.AutoCoding
        var something: Int
        // sourcery:end
        """)
        XCTAssertEqual(match.output.1, "")
        XCTAssertEqual(match.output.2, "inline")
        XCTAssertEqual(match.output.3, "Type.AutoCoding")
        XCTAssertEqual(match.output.4, "var something: Int")
    }

    func test_regex_2() throws {
        let source = """
        ignored
            // sourcery:inline:Type.AutoCoding
            var something: Int
            // sourcery:end
        ignored
        """
        let match = try XCTUnwrap(try sut.regex.firstMatch(in: source))
        XCTAssertEqual(match.output.0, """
            // sourcery:inline:Type.AutoCoding
            var something: Int
            // sourcery:end
        """)
        XCTAssertEqual(match.output.1, "    ")
        XCTAssertEqual(match.output.2, "inline")
        XCTAssertEqual(match.output.3, "Type.AutoCoding")
        XCTAssertEqual(match.output.4, "    var something: Int")
    }

    func test_inline_withoutIndentation() {
        let source = """
        // sourcery:inline:Type.AutoCoding
        var something: Int
        // sourcery:end
        """

        let result = sut.parseAnnotations("inline", content: source, forceParse: [])

        let annotatedRanges = result.annotatedRanges["Type.AutoCoding"]
        XCTAssertEqual(annotatedRanges?.map { $0.range }, [NSRange(location: 35, length: 19)])
        XCTAssertEqual(annotatedRanges?.map { $0.indentation }, [""])
        XCTAssertEqual(result.content,
            "// sourcery:inline:Type.AutoCoding\n" +
            String(repeating: " ", count: 19) +
            "// sourcery:end"
        )
    }

    func test_inline_withoutIndentation_andForceParse() {
        let source = """
        // sourcery:inline:Type.AutoCoding
        var something: Int
        // sourcery:end
        """

        let result = sut.parseAnnotations("inline", content: source, aggregate: false, forceParse: ["AutoCoding"])

        let annotatedRanges = result.annotatedRanges["Type.AutoCoding"]
        XCTAssertEqual(annotatedRanges?.map { $0.range }, [NSRange(location: 35, length: 19)])
        XCTAssertEqual(annotatedRanges?.map { $0.indentation }, [""])
        XCTAssertEqual(result.content, """
        // sourcery:inline:Type.AutoCoding
        var something: Int
        // sourcery:end
        """)
    }

    func test_inline_withIndentation() {
        let source = """
            // sourcery:inline:Type.AutoCoding
            var something: Int
            // sourcery:end
        """

        let result = sut.parseAnnotations("inline", content: source, forceParse: [])

        let annotatedRanges = result.annotatedRanges["Type.AutoCoding"]
        XCTAssertEqual(annotatedRanges?.map { $0.range }, [NSRange(location: 39, length: 23)])
        XCTAssertEqual(annotatedRanges?.map { $0.indentation }, ["    "])
        XCTAssertEqual(result.content,
            "    // sourcery:inline:Type.AutoCoding\n" +
            String(repeating: " ", count: 23) +
            "    // sourcery:end"
        )
    }

    func test_inline_withIndentation_andForceParse() {
        let source = """
            // sourcery:inline:Type.AutoCoding
            var something: Int
            // sourcery:end
        """

        let result = sut.parseAnnotations("inline", content: source, aggregate: false, forceParse: ["AutoCoding"])

        let annotatedRanges = result.annotatedRanges["Type.AutoCoding"]
        XCTAssertEqual(annotatedRanges?.map { $0.range }, [NSRange(location: 39, length: 23)])
        XCTAssertEqual(annotatedRanges?.map { $0.indentation }, ["    "])
        XCTAssertEqual(result.content,
            "    // sourcery:inline:Type.AutoCoding\n" +
            "    var something: Int\n" +
            "    // sourcery:end"
        )
    }
}
