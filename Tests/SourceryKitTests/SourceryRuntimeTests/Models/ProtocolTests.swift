import XCTest
@testable import SourceryKit

class ProtocolTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Protocol(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsProtocol() {
        XCTAssertEqual(sut.kind, "protocol")
    }
}
