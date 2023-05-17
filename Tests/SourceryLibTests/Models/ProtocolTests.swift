import XCTest
@testable import SourceryLib
@testable import SourceryRuntime

class ProtocolTests: XCTestCase {
    var sut: Type!

    override func setUp() {
        sut = Protocol(name: "Foo", variables: [], inheritedTypes: [])
    }

    func test_reportsKindAsProtocol() {
        XCTAssertEqual(sut.kind, "protocol")
    }
}
