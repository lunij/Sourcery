import XCTest
@testable import SourceryKit

class ProtocolTests: XCTestCase {
    var sut: SourceryProtocol!

    override func setUp() {
        sut = Protocol(name: "Foo", associatedTypes: ["bar": .init(name: "Bar")])
    }

    func test_reportsKindAsProtocol() {
        XCTAssertEqual(sut.kind, "protocol")
    }

    func test_equals() {
        XCTAssertEqual(sut, Protocol(name: "Foo", associatedTypes: ["bar": .init(name: "Bar")]))
    }

    func test_differs() {
        XCTAssertNotEqual(sut, Protocol(name: "Foo"))
        XCTAssertNotEqual(sut, Protocol(name: "Bar", associatedTypes: ["foo": .init(name: "Foo")]))
    }
}
