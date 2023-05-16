import XCTest
#if SWIFT_PACKAGE
@testable import SourceryLib
#else
@testable import Sourcery
#endif
@testable import SourceryRuntime

class ClassTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Class(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsClass() {
        XCTAssertEqual(sut.kind, "class")
    }
}
