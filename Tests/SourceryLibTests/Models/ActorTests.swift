import XCTest
@testable import SourceryLib
@testable import SourceryRuntime

class ActorTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Actor(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsActor() {
        XCTAssertEqual(sut.kind, "actor")
    }
}
