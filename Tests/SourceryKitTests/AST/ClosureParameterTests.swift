import XCTest
@testable import SourceryKit

class ClosureParameterTests: XCTestCase {
    func test_initializesWithDefaultParameters() {
        let sut = ClosureParameter(typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut.annotations, [:])
        XCTAssertEqual(sut.argumentLabel, nil)
        XCTAssertEqual(sut.name, nil)
        XCTAssertNil(sut.type)
        XCTAssertNil(sut.defaultValue)
        XCTAssertFalse(sut.isInout)
    }

    func test_initializesWithAttributes() {
        let sut = ClosureParameter(typeName: TypeName(name: "ConversationApiResponse", attributes: ["escaping": [Attribute(name: "escaping")]]))
        XCTAssertEqual(sut.unwrappedTypeName, "ConversationApiResponse")
    }

    func test_initializesWithInoutTrue() {
        let sut = ClosureParameter(typeName: TypeName(name: "Bar"), isInout: true)
        XCTAssertTrue(sut.isInout)
    }

    func test_equals_whenSameItems() {
        let sut = ClosureParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut, ClosureParameter(name: "foo", typeName: TypeName(name: "Int")))
    }

    func test_differs_whenDifferentItems() {
        let sut = ClosureParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertNotEqual(sut, ClosureParameter(name: "bar", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, ClosureParameter(argumentLabel: "bar", name: "foo", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, ClosureParameter(name: "foo", typeName: TypeName(name: "String")))
        XCTAssertNotEqual(sut, ClosureParameter(name: "foo", typeName: TypeName(name: "String"), isInout: true))
    }
}
