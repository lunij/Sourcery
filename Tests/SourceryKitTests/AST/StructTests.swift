import XCTest
@testable import SourceryKit

class StructTests: XCTestCase {
    var sut: Struct!

    override func setUp() {
        sut = Struct(name: "Foo")
    }

    func test_reportsKindAsStruct() {
        XCTAssertEqual(sut.kind, "struct")
    }

    func test_equals() {
        XCTAssertEqual(sut, Struct(name: "Foo"))
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Struct(name: "Bar"))
        XCTAssertNotEqual(sut, Type(name: "Foo"))
    }
}
