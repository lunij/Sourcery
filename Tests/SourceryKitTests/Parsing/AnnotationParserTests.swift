import Foundation
import PathKit
import XCTest
@testable import SourceryKit

class AnnotationParserTests: XCTestCase {
    var sut: AnnotationParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_parseLine_singleAnnotation() {
        let parsedAnnotations = sut.parse(line: "skipEquality")
        XCTAssertEqual(parsedAnnotations, ["skipEquality": NSNumber(value: true)])
    }

    func test_parseLine_repeatedAnnotationsIntoArray() {
        let parsedAnnotations = sut.parse(line: "implements = \"Service1\", implements = \"Service2\"")
        XCTAssertEqual(parsedAnnotations["implements"] as? [String], ["Service1", "Service2"])
    }

    func test_parseLine_multipleAnnotationsOnTheSameLine() {
        let parsedAnnotations = sut.parse(line: "skipEquality, jsonKey = \"json_key\"")
        XCTAssertEqual(parsedAnnotations, [
            "skipEquality": NSNumber(value: true),
            "jsonKey": "json_key" as NSString
        ])
    }

    func test_parsesInlineAnnotations() {
        let parsedAnnotations = sut.parse("""
        // sourcery: skipDescription
        /* sourcery: skipEquality */
        /** sourcery: skipCoding */
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations, [
            "skipDescription": NSNumber(value: true),
            "skipEquality": NSNumber(value: true),
            "skipCoding": NSNumber(value: true)
        ])
    }

    func test_parsesInlineAnnotationsFromMultilineComments() {
        let parsedAnnotations = sut.parse("""
        /**
         * Comment
         * sourcery: skipDescription
         * sourcery: skipEquality
         */
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations, [
            "skipDescription": NSNumber(value: true),
            "skipEquality": NSNumber(value: true)
        ])
    }

    func test_parsesMultilineAnnotationsIncludingNumbers() {
        let parsedAnnotations = sut.parse("""
        // sourcery: skipEquality, jsonKey = [\"json_key\": key, \"json_value\": value]
        // sourcery: thirdProperty = -3
        // sourcery: placeholder = \"geo:37.332112,-122.0329753?q=1 Infinite Loop\"
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations, [
            "skipEquality": NSNumber(value: true),
            "placeholder": "geo:37.332112,-122.0329753?q=1 Infinite Loop" as NSString,
            "jsonKey": "[\"json_key\": key, \"json_value\": value]" as NSString,
            "thirdProperty": NSNumber(value: -3)
        ])
    }

    func test_parsesRepeatedAnnotationsIntoArray() {
        let parsedAnnotations = sut.parse("// sourcery: implements = \"Service1\"\n// sourcery: implements = \"Service2\"")
        XCTAssertEqual(parsedAnnotations["implements"] as? [String], ["Service1", "Service2"])
    }

    func test_parsesAnnotationsInterleavedWithComments() {
        let parsedAnnotations = sut.parse("""
        // sourcery: isSet
        /// isSet is used for something useful
        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations, [
            "isSet": NSNumber(value: true),
            "numberOfIterations": NSNumber(value: 2)
        ])
    }

    func test_parsesEndOfLineAnnotations() {
        let parsedAnnotations = sut.parse(#"""
        // sourcery: first = 1
        let property: Int // sourcery: second = 2, third = "three"
        """#)
        XCTAssertEqual(parsedAnnotations, [
            "first": NSNumber(value: 1),
            "second": NSNumber(value: 2),
            "third": "three" as NSString
        ])
    }

    func test_parsesEndOfLineBlockCommentAnnotations() {
        let parsedAnnotations = sut.parse(#"""
        // sourcery: first = 1
        let property: Int /* sourcery: second = 2, third = "three" */ // comment
        """#)
        XCTAssertEqual(parsedAnnotations, [
            "first": NSNumber(value: 1),
            "second": NSNumber(value: 2),
            "third": "three" as NSString
        ])
    }

    func test_ignoresAnnotationsInStringLiterals() {
        let parsedAnnotations = sut.parse(#"""
        // sourcery: first = 1
        let property = "// sourcery: second = 2" // sourcery: third = 3
        """#)
        XCTAssertEqual(parsedAnnotations, [
            "first": NSNumber(value: 1),
            "third": NSNumber(value: 3)
        ])
    }

    func test_parsesFileAnnotations() {
        let parsedAnnotations = sut.parse("""
        // sourcery:file: isSet
        /// isSet is used for something useful
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations, ["isSet": NSNumber(value: true)])
    }

    func test_parsesNamespaceAnnotations() {
        let parsedAnnotations = sut.parse("""
        // sourcery:decoding:smth: key='aKey', default=0
        // sourcery:decoding:smth: prune
        var name: Int { return 2 }
        """)
        XCTAssertEqual(parsedAnnotations["decoding"] as? Annotations, [
            "smth": ["key": "aKey" as NSObject, "default": NSNumber(value: 0), "prune": NSNumber(value: true)] as NSObject
        ])
    }

    func test_parsesJsonStringAnnotationsIntoArray() {
        let parsedAnnotations = sut.parse(#"// sourcery: theArray="[22,55,88]""#)
        XCTAssertEqual(parsedAnnotations["theArray"] as? [Int], [22, 55, 88])
    }

    func test_parsesJsonStringAnnotationsIntoArraysOfDictionaries() {
        let parsedAnnotations = sut.parse("// sourcery: propertyMapping=\"[{\"from\": \"lockVersion\", \"to\": \"version\"},{\"from\": \"goalStatus\", \"to\": \"status\"}]\"")
        XCTAssertEqual(parsedAnnotations["propertyMapping"] as? [[String: String]], [["from": "lockVersion", "to": "version"], ["from": "goalStatus", "to": "status"]])
    }

    func test_parsesJsonStringAnnotationsIntoDictionary() {
        let parsedAnnotations = sut.parse("// sourcery: theDictionary=\"{\"firstValue\": 22,\"secondValue\": 55}\"")
        XCTAssertEqual(parsedAnnotations["theDictionary"] as? [String: Int], ["firstValue": 22, "secondValue": 55])
    }

    func test_parsesJsonStringAnnotationsIntoDictionariesOfArrays() {
        let parsedAnnotations = sut.parse("// sourcery: theArrays=\"{\"firstArray\":[22,55,88],\"secondArray\":[1,2,3,4]}\"")
        XCTAssertEqual(parsedAnnotations["theArrays"] as? [String: [Int]], ["firstArray": [22, 55, 88], "secondArray": [1, 2, 3, 4]])
    }
}

private extension AnnotationParser {
    func parse(_ content: String) -> Annotations {
        let lines: [Line] = parse(contents: content)
        var annotations = Annotations()
        for line in lines {
            for annotation in line.annotations {
                annotations.append(key: annotation.key, value: annotation.value)
            }
        }
        return annotations
    }
}
