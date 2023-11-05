import XCTest
@testable import SourceryKit

class ClassTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Class(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsClass() {
        XCTAssertEqual(sut.kind, "class")
    }
}
