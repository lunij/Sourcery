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

    func test_parsesInlineAnnotations() {
        let annotations = sut.parse("""
        // sourcery: skipDescription
        /* sourcery: skipEquality */
        /** sourcery: skipCoding */
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: skipDescription", type: .comment, annotations: ["skipDescription": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "/* sourcery: skipEquality */", type: .comment, annotations: ["skipEquality": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "/** sourcery: skipCoding */", type: .documentationComment, annotations: ["skipCoding": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: [:], blockAnnotations: [:])
        ])
    }

    func test_parsesInlineAnnotationsFromMultilineComments() {
        let annotations = sut.parse("""
        /**
         * Comment
         * sourcery: skipDescription
         * sourcery: skipEquality
         */
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "/**", type: .documentationComment, annotations: [:], blockAnnotations: [:]),
            .init(content: " * Comment", type: .comment, annotations: [:], blockAnnotations: [:]),
            .init(content: " * sourcery: skipDescription", type: .comment, annotations: ["skipDescription": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: " * sourcery: skipEquality", type: .comment, annotations: ["skipEquality": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: " */", type: .comment, annotations: [:], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: [:], blockAnnotations: [:])
        ])
    }

    func test_parsesMultilineAnnotationsIncludingNumbers() {
        let annotations = sut.parse("""
        // sourcery: skipEquality, jsonKey = [\"json_key\": key, \"json_value\": value]
        // sourcery: thirdProperty = -3
        // sourcery: placeholder = \"geo:37.332112,-122.0329753?q=1 Infinite Loop\"
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: skipEquality, jsonKey = [\"json_key\": key, \"json_value\": value]", type: .comment, annotations: ["jsonKey": "[\"json_key\": key, \"json_value\": value]" as NSString, "skipEquality": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "// sourcery: thirdProperty = -3", type: .comment, annotations: ["thirdProperty": NSNumber(value: -3)], blockAnnotations: [:]),
            .init(content: "// sourcery: placeholder = \"geo:37.332112,-122.0329753?q=1 Infinite Loop\"", type: .comment, annotations: ["placeholder": "geo:37.332112,-122.0329753?q=1 Infinite Loop" as NSString], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: [:], blockAnnotations: [:])
        ])
    }

    func test_parsesRepeatedAnnotationsIntoArray() {
        let annotations = sut.parse("// sourcery: implements = \"Service1\"\n// sourcery: implements = \"Service2\"")
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: implements = \"Service1\"", type: .comment, annotations: ["implements": "Service1" as NSString], blockAnnotations: [:]),
            .init(content: "// sourcery: implements = \"Service2\"", type: .comment, annotations: ["implements": "Service2" as NSString], blockAnnotations: [:])
        ])
    }

    func test_parsesAnnotationsInterleavedWithComments() {
        let annotations = sut.parse("""
        // sourcery: isSet
        /// isSet is used for something useful
        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: isSet", type: .comment, annotations: ["isSet": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "/// isSet is used for something useful", type: .documentationComment, annotations: [:], blockAnnotations: [:]),
            .init(content: "// sourcery: numberOfIterations = 2", type: .comment, annotations: ["numberOfIterations": NSNumber(value: 2)], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: [:], blockAnnotations: [:])
        ])
    }

    func test_parsesEndOfLineAnnotations() {
        let annotations = sut.parse(#"""
        // sourcery: first = 1
        let property: Int // sourcery: second = 2, third = "three"
        """#)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: first = 1", type: .comment, annotations: ["first": NSNumber(value: 1)], blockAnnotations: [:]),
            .init(content: "let property: Int // sourcery: second = 2, third = \"three\"", type: .other, annotations: ["third": "three" as NSString, "second": NSNumber(value: 2)], blockAnnotations: [:])
        ])
    }

    func test_parsesEndOfLineBlockCommentAnnotations() {
        let annotations = sut.parse(#"""
        // sourcery: first = 1
        let property: Int /* sourcery: second = 2, third = "three" */ // comment
        """#)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: first = 1", type: .comment, annotations: ["first": NSNumber(value: 1)], blockAnnotations: [:]),
            .init(content: "let property: Int /* sourcery: second = 2, third = \"three\" */ // comment", type: .other, annotations: ["second": NSNumber(value: 2), "third": "three" as NSString], blockAnnotations: [:])
        ])
    }

    func test_ignoresAnnotationsInStringLiterals() {
        let annotations = sut.parse(#"""
        // sourcery: first = 1
        let property = "// sourcery: second = 2" // sourcery: third = 3
        """#)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: first = 1", type: .comment, annotations: ["first": NSNumber(value: 1)], blockAnnotations: [:]),
            .init(content: "let property = \"// sourcery: second = 2\" // sourcery: third = 3", type: .other, annotations: ["third": NSNumber(value: 3)], blockAnnotations: [:])
        ])
    }

    func test_parsesFileAnnotations() {
        let annotations = sut.parse("""
        // sourcery:file: isSet
        /// isSet is used for something useful
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery:file: isSet", type: .file, annotations: ["isSet": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "/// isSet is used for something useful", type: .documentationComment, annotations: ["isSet": NSNumber(value: true)], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: ["isSet": NSNumber(value: true)], blockAnnotations: [:])
        ])
    }

    func test_parsesNamespaceAnnotations() {
        let annotations = sut.parse("""
        // sourcery:decoding:smth: key='aKey', default=0
        // sourcery:decoding:smth: prune
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery:decoding:smth: key=\'aKey\', default=0", type: .comment, annotations: ["decoding": ["smth": ["key": "aKey" as NSObject, "default": NSNumber(value: 0)] as NSDictionary] as NSDictionary], blockAnnotations: [:]),
            .init(content: "// sourcery:decoding:smth: prune", type: .comment, annotations: ["decoding": ["smth": ["prune": NSNumber(value: true)] as NSObject] as NSDictionary], blockAnnotations: [:]),
            .init(content: "var name: Int { return 2 }", type: .other, annotations: [:], blockAnnotations: [:])
        ])
    }

    func test_parsesJsonStringAnnotationsIntoArray() {
        let annotations = sut.parse(#"// sourcery: theArray="[22,55,88]""#)
        XCTAssertEqual(annotations, [
            .init(content: "// sourcery: theArray=\"[22,55,88]\"", type: .comment, annotations: ["theArray": [22, 55, 88] as NSArray], blockAnnotations: [:])
        ])
    }

    func test_parsesJsonStringAnnotationsIntoArraysOfDictionaries() {
        let annotations = sut.parse(#"// sourcery: propertyMapping="[{"from": "lockVersion", "to": "version"},{"from": "goalStatus", "to": "status"}]""#)
        XCTAssertEqual(annotations, [
            .init(
                content: #"// sourcery: propertyMapping="[{"from": "lockVersion", "to": "version"},{"from": "goalStatus", "to": "status"}]""#,
                type: .comment,
                annotations: [
                    "propertyMapping": [
                        [
                            "from": "lockVersion",
                            "to": "version"
                        ] as NSDictionary,
                        [
                            "from": "goalStatus",
                            "to": "status"
                        ] as NSDictionary
                    ] as NSArray
                ],
                blockAnnotations: [:]
            )
        ])
    }

    func test_parsesJsonStringAnnotationsIntoDictionary() {
        let annotations = sut.parse(#"// sourcery: theDictionary="{"firstValue": 22,"secondValue": 55}""#)
        XCTAssertEqual(annotations, [
            .init(
                content: #"// sourcery: theDictionary="{"firstValue": 22,"secondValue": 55}""#,
                type: .comment,
                annotations: [
                    "theDictionary": [
                        "firstValue": 22 as NSNumber,
                        "secondValue": 55 as NSNumber
                    ] as NSDictionary
                ],
                blockAnnotations: [:]
            )
        ])
    }

    func test_parsesJsonStringAnnotationsIntoDictionariesOfArrays() {
        let annotations = sut.parse(#"// sourcery: theArrays="{"firstArray":[22,55,88],"secondArray":[1,2,3,4]}""#)
        XCTAssertEqual(annotations, [
            .init(
                content: #"// sourcery: theArrays="{"firstArray":[22,55,88],"secondArray":[1,2,3,4]}""#,
                type: .comment,
                annotations: [
                    "theArrays": [
                        "firstArray": [22, 55, 88] as NSArray,
                        "secondArray": [1, 2, 3, 4] as NSArray
                    ] as NSDictionary
                ],
                blockAnnotations: [:]
            )
        ])
    }
}
