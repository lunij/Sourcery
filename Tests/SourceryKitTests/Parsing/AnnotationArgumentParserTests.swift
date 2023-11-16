import XCTest
@testable import SourceryKit

class AnnotationArgumentParserTests: XCTestCase {
    var sut: AnnotationArgumentParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_parseLine_singleAnnotation() throws {
        let parsedAnnotations = try sut.parseArguments(from: "skipEquality")
        XCTAssertEqual(parsedAnnotations, ["skipEquality": true])
    }

    func test_parseLine_repeatedAnnotationsIntoArray() throws {
        let parsedAnnotations = try sut.parseArguments(from: "implements = \"Service1\", implements = \"Service2\"")
        XCTAssertEqual(parsedAnnotations, ["implements": ["Service1", "Service2"]])
    }

    func test_parseLine_multipleAnnotationsOnTheSameLine() throws {
        let parsedAnnotations = try sut.parseArguments(from: "skipEquality, jsonKey = \"json_key\"")
        XCTAssertEqual(parsedAnnotations, [
            "skipEquality": true,
            "jsonKey": "json_key"
        ])
    }

    func test_parsesBool() throws {
        let annotations = try sut.parseArguments(from: "theBoolean=true")
        XCTAssertEqual(annotations, ["theBoolean": true])
    }

    func test_parsesDouble() throws {
        let annotations = try sut.parseArguments(from: "theDouble=13.37")
        XCTAssertEqual(annotations, ["theDouble": 13.37])
    }

    func test_parsesInteger() throws {
        let annotations = try sut.parseArguments(from: "theInteger=1337")
        XCTAssertEqual(annotations, ["theInteger": 1337])
    }

    func test_parsesString() throws {
        let annotations = try sut.parseArguments(from: #"theString="this is a string""#)
        XCTAssertEqual(annotations, ["theString": "this is a string"])
    }

    func test_parsesJsonArray() throws {
        let annotations = try sut.parseArguments(from: "theArray=[22,55,88]")
        XCTAssertEqual(annotations, ["theArray": [22, 55, 88]])
    }

    func test_parsesJsonObject() throws {
        let annotations = try sut.parseArguments(from: #"json = {"key1": 1337, "key2": "foo"}"#)
        XCTAssertEqual(annotations, ["json": ["key1": 1337, "key2": "foo"]])
    }
}
