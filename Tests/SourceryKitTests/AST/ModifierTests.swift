import XCTest
@testable import SourceryKit

class ModifierTests: XCTestCase {
    var sut: Modifier!

    override func setUp() {
        sut = Modifier(name: "private", detail: "set")
    }

    func test_equals() {
        XCTAssertEqual(sut, sut)
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Modifier(name: "private"))
        XCTAssertNotEqual(sut, Modifier(name: "public"))
    }

    func test_description() {
        XCTAssertEqual(sut.description, "private(set)")
        XCTAssertEqual(Modifier(name: "public").description, "public")
    }
}
