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
        // sourcery: foo = "🌍"
        /* sourcery: skipEquality */
        /** sourcery: skipCoding */
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, ["foo": "🌍", "skipEquality": true, "skipCoding": true])
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
        XCTAssertEqual(annotations, ["skipDescription": true, "skipEquality": true])
    }

    func test_parsesMultilineAnnotationsIncludingNumbers() {
        let annotations = sut.parse("""
        // sourcery: skipEquality, jsonKey = "[\\"json_key\\": key, \\"json_value\\": value]"
        // sourcery: thirdProperty = -3
        // sourcery: placeholder = "geo:37.332112,-122.0329753?q=1 Infinite Loop"
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            "jsonKey": "[\"json_key\": key, \"json_value\": value]",
            "skipEquality": true,
            "thirdProperty": -3,
            "placeholder": "geo:37.332112,-122.0329753?q=1 Infinite Loop"
        ])
    }

    func test_parsesRepeatedAnnotationsIntoArray() {
        let annotations = sut.parse("""
        // sourcery: implements = \"Service1\"
        // sourcery: implements = \"Service2\"
        """)
        XCTAssertEqual(annotations, ["implements": ["Service1", "Service2"]])
    }

    func test_parsesAnnotationsInterleavedWithComments() {
        let annotations = sut.parse("""
        // sourcery: isSet
        /// isSet is used for something useful
        // sourcery: numberOfIterations = 2
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, ["isSet": true, "numberOfIterations": 2])
    }

    func test_ignoresAnnotationsInStringLiterals() {
        let annotations = sut.parse(#"""
        // sourcery: first
        let property = "// sourcery: ignored"
        """#)
        XCTAssertEqual(annotations, ["first": true])
    }

    func test_ignoresTrailingAnnotations() {
        let annotations = sut.parse(#"""
        // sourcery: first
        let property = "foobar" // sourcery: ignored
        """#)
        XCTAssertEqual(annotations, ["first": true])
    }

    func test_parsesNamespaceAnnotations() {
        let annotations = sut.parse("""
        // sourcery:decoding:smth: key='aKey', default=0
        // sourcery:decoding:smth: prune
        var name: Int { return 2 }
        """)
        XCTAssertEqual(annotations, [
            "decoding": [
                "smth": [
                    "key": "aKey",
                    "default": 0,
                    "prune": true
                ]
            ]
        ])
    }

    func test_parsesJsonStringAnnotationsIntoArray() {
        let annotations = sut.parse("// sourcery: theArray=[22,55,88]")
        XCTAssertEqual(annotations, ["theArray": [22, 55, 88]])
    }

    func test_parsesJsonStringAnnotationsIntoArraysOfDictionaries() {
        let annotations = sut.parse(#"// sourcery: propertyMapping=[{"from": "lockVersion", "to": "version"},{"from": "goalStatus", "to": "status"}]"#)
        XCTAssertEqual(annotations, [
            "propertyMapping": [
                [
                    "from": "lockVersion",
                    "to": "version"
                ],
                [
                    "from": "goalStatus",
                    "to": "status"
                ]
            ]
        ])
    }

    func test_parsesJsonStringAnnotationsIntoDictionary() {
        let annotations = sut.parse(#"// sourcery: theDictionary={"firstValue": 22,"secondValue": 55}"#)
        XCTAssertEqual(annotations, [
            "theDictionary": [
                "firstValue": 22,
                "secondValue": 55
            ]
        ])
    }

    func test_parsesJsonStringAnnotationsIntoDictionariesOfArrays() {
        let annotations = sut.parse(#"// sourcery: theArrays={"firstArray":[22,55,88],"secondArray":[1,2,3,4]}"#)
        XCTAssertEqual(annotations, [
            "theArrays": [
                "firstArray": [22, 55, 88],
                "secondArray": [1, 2, 3, 4]
            ]
        ])
    }
}
