import Foundation
import PathKit
import XCTest
@testable import SourceryFramework
@testable import SourceryLib
@testable import SourceryRuntime

class AnnotationsParserTests: XCTestCase {
    func test_parseLine_singleAnnotation() {
        let expectedAnnotations = ["skipEquality": NSNumber(value: true)]
        let parsedAnnotations = AnnotationsParser.parse(line: "skipEquality")

        XCTAssertEqual(parsedAnnotations, expectedAnnotations)
    }

    func test_parseLine_repeatedAnnotationsIntoArray() {
        let parsedAnnotations = AnnotationsParser.parse(line: "implements = \"Service1\", implements = \"Service2\"")

        XCTAssertEqual(parsedAnnotations["implements"] as? [String], ["Service1", "Service2"])
    }

    func test_parseLine_multipleAnnotationsOnTheSameLine() {
        let expectedAnnotations = [
            "skipEquality": NSNumber(value: true),
            "jsonKey": "json_key" as NSString
        ]
        let parsedAnnotations = AnnotationsParser.parse(line: "skipEquality, jsonKey = \"json_key\"")

        XCTAssertEqual(parsedAnnotations, expectedAnnotations)
    }

    func test_parsesInlineAnnotations() {
        let parsedAnnotations = "//sourcery: skipDescription\n/* sourcery: skipEquality */\n/** sourcery: skipCoding */var name: Int { return 2 }".parse()
        XCTAssertEqual(parsedAnnotations, [
            "skipDescription": NSNumber(value: true),
            "skipEquality": NSNumber(value: true),
            "skipCoding": NSNumber(value: true)
        ])
    }

    func test_parsesInlineAnnotationsFromMultilineComments() {
        let parsedAnnotations = "//**\n*Comment\n*sourcery: skipDescription\n*sourcery: skipEquality\n*/var name: Int { return 2 }".parse()
        XCTAssertEqual(parsedAnnotations, [
            "skipDescription": NSNumber(value: true),
            "skipEquality": NSNumber(value: true)
        ])
    }

    func test_parsesMultilineAnnotationsIncludingNumbers() {
        let expectedAnnotations = [
            "skipEquality": NSNumber(value: true),
            "placeholder": "geo:37.332112,-122.0329753?q=1 Infinite Loop" as NSString,
            "jsonKey": "[\"json_key\": key, \"json_value\": value]" as NSString,
            "thirdProperty": NSNumber(value: -3)
        ]
        let parsedAnnotations = """
        // sourcery: skipEquality, jsonKey = [\"json_key\": key, \"json_value\": value]
        // sourcery: thirdProperty = -3
        // sourcery: placeholder = \"geo:37.332112,-122.0329753?q=1 Infinite Loop\"
        var name: Int { return 2 }
        """.parse()
        XCTAssertEqual(parsedAnnotations, expectedAnnotations)
    }

    func test_parsesRepeatedAnnotationsIntoArray() {
        let parsedAnnotations = "// sourcery: implements = \"Service1\"\n// sourcery: implements = \"Service2\"".parse()
        XCTAssertEqual(parsedAnnotations["implements"] as? [String], ["Service1", "Service2"])
    }

    func test_parsesAnnotationsInterleavedWithComments() {
        let expectedAnnotations = [
            "isSet": NSNumber(value: true),
            "numberOfIterations": NSNumber(value: 2)
        ]
        let parsedAnnotations = """
        // sourcery: isSet
        /// isSet is used for something useful
        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """.parse()
        XCTAssertEqual(parsedAnnotations, expectedAnnotations)
    }

    func test_parsesEndOfLineAnnotations() {
        let parsedAnnotations = "// sourcery: first = 1 \n let property: Int // sourcery: second = 2, third = \"three\"".parse()
        XCTAssertEqual(parsedAnnotations, ["first": NSNumber(value: 1), "second": NSNumber(value: 2), "third": "three" as NSString])
    }

    func test_parsesEndOfLineBlockCommentAnnotations() {
        let parsedAnnotations = "// sourcery: first = 1 \n let property: Int /* sourcery: second = 2, third = \"three\" */ // comment".parse()
        XCTAssertEqual(parsedAnnotations, ["first": NSNumber(value: 1), "second": NSNumber(value: 2), "third": "three" as NSString])
    }

    func test_ignoresAnnotationsInStringLiterals() {
        let parsedAnnotations = "// sourcery: first = 1 \n let property = \"// sourcery: second = 2\" // sourcery: third = 3".parse()
        XCTAssertEqual(parsedAnnotations, ["first": NSNumber(value: 1), "third": NSNumber(value: 3)])
    }

    func test_parsesFileAnnotations() {
        let expectedAnnotations = ["isSet": NSNumber(value: true)]
        let parsedAnnotations = """
        // sourcery:file: isSet
        /// isSet is used for something useful
        var name: Int { return 2 }
        """.parse()
        XCTAssertEqual(parsedAnnotations, expectedAnnotations)
    }

    func test_parsesNamespaceAnnotations() {
        let expectedAnnotations: [String: NSObject] = ["smth": ["key": "aKey" as NSObject, "default": NSNumber(value: 0), "prune": NSNumber(value: true)] as NSObject]
        let parsedAnnotations = """
        // sourcery:decoding:smth: key='aKey', default=0
        // sourcery:decoding:smth: prune
        var name: Int { return 2 }
        """.parse()
        XCTAssertEqual(parsedAnnotations["decoding"] as? Annotations, expectedAnnotations)
    }

    func test_parsesJsonStringAnnotationsIntoArray() {
        let parsedAnnotations = "// sourcery: theArray=\"[22,55,88]\"".parse()
        XCTAssertEqual(parsedAnnotations["theArray"] as? [Int], [22, 55, 88])
    }

    func test_parsesJsonStringAnnotationsIntoArraysOfDictionaries() {
        let parsedAnnotations = "// sourcery: propertyMapping=\"[{\"from\": \"lockVersion\", \"to\": \"version\"},{\"from\": \"goalStatus\", \"to\": \"status\"}]\"".parse()
        XCTAssertEqual(parsedAnnotations["propertyMapping"] as? [[String: String]], [["from": "lockVersion", "to": "version"], ["from": "goalStatus", "to": "status"]])
    }

    func test_parsesJsonStringAnnotationsIntoDictionary() {
        let parsedAnnotations = "// sourcery: theDictionary=\"{\"firstValue\": 22,\"secondValue\": 55}\"".parse()
        XCTAssertEqual(parsedAnnotations["theDictionary"] as? [String: Int], ["firstValue": 22, "secondValue": 55])
    }

    func test_parsesJsonStringAnnotationsIntoDictionariesOfArrays() {
        let parsedAnnotations = "// sourcery: theArrays=\"{\"firstArray\":[22,55,88],\"secondArray\":[1,2,3,4]}\"".parse()
        XCTAssertEqual(parsedAnnotations["theArrays"] as? [String: [Int]], ["firstArray": [22, 55, 88], "secondArray": [1, 2, 3, 4]])
    }
}

private extension String {
    func parse() -> Annotations {
        AnnotationsParser(contents: self).all
    }
}
