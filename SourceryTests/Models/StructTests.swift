import XCTest
#if SWIFT_PACKAGE
@testable import SourceryLib
#else
@testable import Sourcery
#endif
@testable import SourceryRuntime

class StructTests: XCTestCase {
    var sut: Struct!

    override func setUp() {
        sut = Struct(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsStruct() {
        XCTAssertEqual(sut.kind, "struct")
    }
}
