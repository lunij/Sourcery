import XCTest
@testable import SourceryKit

class ProtocolCompositionTests: XCTestCase {
    var sut: ProtocolComposition!

    override func setUp() {
        sut = ProtocolComposition(name: "Foo", composedTypeNames: [.init(name: "Bar")])
    }

    func test_reportsKindAsProtocol() {
        XCTAssertEqual(sut.kind, "protocolComposition")
    }

    func test_equals() {
        XCTAssertEqual(sut, ProtocolComposition(name: "Foo", composedTypeNames: [.init(name: "Bar")]))
    }

    func test_differs() {
        XCTAssertNotEqual(sut, ProtocolComposition(name: "Foo"))
        XCTAssertNotEqual(sut, ProtocolComposition(name: "Foo", composedTypeNames: [.init(name: "Foo")]))
        XCTAssertNotEqual(sut, Type(name: "Foo"))
    }
}
