import XCTest
@testable import SourceryKit

class MethodParameterTests: XCTestCase {
    func test_initializesWithDefaultParameters() {
        let sut = MethodParameter(typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut.annotations, [:])
        XCTAssertEqual(sut.argumentLabel, "")
        XCTAssertEqual(sut.name, "")
        XCTAssertNil(sut.type)
        XCTAssertNil(sut.defaultValue)
        XCTAssertFalse(sut.inout)
    }

    func test_initializesWithAttributes() {
        let sut = MethodParameter(typeName: TypeName(name: "ConversationApiResponse", attributes: ["escaping": [Attribute(name: "escaping")]]))
        XCTAssertEqual(sut.unwrappedTypeName, "ConversationApiResponse")
    }

    func test_initializesWithInoutTrue() {
        let sut = MethodParameter(typeName: TypeName(name: "Bar"), isInout: true)
        XCTAssertTrue(sut.inout)
    }

    func test_equals_whenSameItems() {
        let sut = MethodParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut, MethodParameter(name: "foo", typeName: TypeName(name: "Int")))
    }

    func test_differs_whenDifferentItems() {
        let sut = MethodParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertNotEqual(sut, MethodParameter(name: "bar", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, MethodParameter(argumentLabel: "bar", name: "foo", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, MethodParameter(name: "foo", typeName: TypeName(name: "String")))
        XCTAssertNotEqual(sut, MethodParameter(name: "foo", typeName: TypeName(name: "String"), isInout: true))
    }
}
