import XCTest
@testable import SourceryKit

class StructTests: XCTestCase {
    var sut: Struct!

    override func setUp() {
        sut = Struct(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsStruct() {
        XCTAssertEqual(sut.kind, "struct")
    }
}
