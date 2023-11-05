import XCTest
@testable import SourceryKit

class ActorTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Actor(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsActor() {
        XCTAssertEqual(sut.kind, "actor")
    }
}
