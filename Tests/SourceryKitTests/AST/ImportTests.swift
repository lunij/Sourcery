import XCTest
@testable import SourceryKit

class ImportTests: XCTestCase {
    var sut: Import!

    override func setUp() {
        sut = Import("Foundation")
    }

    func test_equals() {
        XCTAssertEqual(sut, sut)
        XCTAssertEqual(Import(kind: "struct", path: "FakeModule.FakeStruct"), Import(kind: "struct", path: "FakeModule.FakeStruct"))
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Import("Foundational"))
        XCTAssertNotEqual(sut, Import(kind: "enum", path: "FakeModule.FakeEnum"))
    }

    func test_description() {
        XCTAssertEqual(sut.description, "Foundation")
        XCTAssertEqual(Import(kind: "class", path: "FakeModule.FakeClass").description, "class FakeModule.FakeClass")
    }
}
