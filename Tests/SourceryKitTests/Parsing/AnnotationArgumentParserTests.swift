import XCTest
@testable import SourceryKit

class AnnotationArgumentParserTests: XCTestCase {
    var sut: AnnotationArgumentParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_parseLine_singleAnnotation() {
        let parsedAnnotations = sut.parseArguments(from: "skipEquality")
        XCTAssertEqual(parsedAnnotations, ["skipEquality": NSNumber(value: true)])
    }

    func test_parseLine_repeatedAnnotationsIntoArray() {
        let parsedAnnotations = sut.parseArguments(from: "implements = \"Service1\", implements = \"Service2\"")
        XCTAssertEqual(parsedAnnotations["implements"] as? [String], ["Service1", "Service2"])
    }

    func test_parseLine_multipleAnnotationsOnTheSameLine() {
        let parsedAnnotations = sut.parseArguments(from: "skipEquality, jsonKey = \"json_key\"")
        XCTAssertEqual(parsedAnnotations, [
            "skipEquality": NSNumber(value: true),
            "jsonKey": "json_key" as NSString
        ])
    }
}
