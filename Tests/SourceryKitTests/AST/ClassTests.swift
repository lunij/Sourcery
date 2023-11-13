import XCTest
@testable import SourceryKit

class ClassTests: XCTestCase {
    var sut: Class!

    override func setUp() {
        sut = Class(name: "Foo")
    }

    func test_reportsKindAsClass() {
        XCTAssertEqual(sut.kind, "class")
    }

    func test_equals() {
        XCTAssertEqual(sut, Class(name: "Foo"))
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Class(name: "Bar"))
        XCTAssertNotEqual(sut, Type(name: "Foo"))
    }
}
