import Foundation
import XCTest
@testable import SourceryRuntime

class DiffableTests: XCTestCase {
    var sut = DiffableResult()

    override func setUp() {
        sut = DiffableResult()
    }

    func test_isEmpty_whenEmpty() {
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_whenNotEmpty() {
        sut.append("Something")
        XCTAssertFalse(sut.isEmpty)
    }

    func test_appendsElement() {
        sut.append("Expected value")
        XCTAssertEqual("\(sut)", "Expected value")
    }

    func test_addsNewlineSeparatorBetweenElements() {
        sut.append("Value 1")
        sut.append("Value 2")
        XCTAssertEqual("\(sut)", "Value 1\nValue 2")
    }

    func test_processesIdentifierForAllElements() {
        sut.identifier = "Prefixed"
        sut.append("Value 1")
        sut.append("Value 2")
        XCTAssertEqual("\(sut)", "Prefixed Value 1\nValue 2")
    }

    func test_joinsTwoDiffableResults() {
        sut.append("Value 1")
        sut.append(contentsOf: DiffableResult(results: ["Value 2"]))
        XCTAssertEqual("\(sut)", "Value 1\nValue 2")
    }

    func test_trackDifference_givenNotDiffableElements_addsThemIfNotEqual() {
        sut.trackDifference(actual: 3, expected: 5)
        XCTAssertEqual("\(sut)", "<expected: 5, received: 3>")
    }

    func test_trackDifference_givenNotDiffableElements_doesNotAddThemIfEqual() {
        sut.trackDifference(actual: 3, expected: 3)
        XCTAssertEqual("\(sut)", "")
    }

    func test_trackDifference_givenDiffableElements_addsThemIfNotEqual() {
        sut.trackDifference(actual: Type(name: "Foo"), expected: Type(name: "Bar"))
        XCTAssertEqual("\(sut)", "localName <expected: Bar, received: Foo>")
    }

    func test_trackDifference_givenDiffableElements_doesNotAddThemIfEqual() {
        sut.trackDifference(actual: Type(name: "Foo"), expected: Type(name: "Foo"))
        XCTAssertEqual("\(sut)", "")
    }

    func test_trackDifference_arrays_findsDifferenceInCount() {
        sut.trackDifference(
            actual: [Type(name: "Foo")],
            expected: [Type(name: "Foo"), Type(name: "Foo2")]
        )
        XCTAssertEqual("\(sut)", "Different count, expected: 2, received: 1")
    }

    func test_trackDifference_arrays_findsDifferenceAtIndex() {
        sut.trackDifference(
            actual: [Type(name: "Foo"), Type(name: "Foo")],
            expected: [Type(name: "Foo"), Type(name: "Foo2")]
        )
        XCTAssertEqual("\(sut)", "idx 1: localName <expected: Foo2, received: Foo>")
    }

    func test_trackDifference_arrays_findsDifferenceAtMultipleIndices() {
        sut.trackDifference(
            actual: [Type(name: "FooBar"), Type(name: "Foo")],
            expected: [Type(name: "Foo"), Type(name: "Foo2")]
        )
        XCTAssertEqual("\(sut)", "idx 0: localName <expected: Foo, received: FooBar>\nidx 1: localName <expected: Foo2, received: Foo>")
    }

    func test_trackDifference_dictionaries_findsDifferenceInCount() {
        sut.trackDifference(
            actual: ["Key": Type(name: "Foo")],
            expected: ["Key": Type(name: "Foo"), "Something": Type(name: "Bar")]
        )
        XCTAssertEqual("\(sut)", "Different count, expected: 2, received: 1\nMissing keys: Something")
    }

    func test_trackDifference_dictionaries_findsDifferenceInKeyCount() {
        sut.trackDifference(
            actual: ["Key": Type(name: "Foo"), "Something": Type(name: "FooBar")],
            expected: ["Key": Type(name: "Foo"), "Something": Type(name: "Bar")]
        )
        XCTAssertEqual("\(sut)", "key \"Something\": localName <expected: Bar, received: FooBar>")
    }
}
