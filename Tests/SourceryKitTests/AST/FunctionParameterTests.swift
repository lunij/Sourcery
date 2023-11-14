import XCTest
@testable import SourceryKit

class FunctionParameterTests: XCTestCase {
    func test_initializesWithDefaultParameters() {
        let sut = FunctionParameter(typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut.annotations, [:])
        XCTAssertEqual(sut.argumentLabel, "")
        XCTAssertEqual(sut.name, "")
        XCTAssertNil(sut.type)
        XCTAssertNil(sut.defaultValue)
        XCTAssertFalse(sut.inout)
    }

    func test_initializesWithAttributes() {
        let sut = FunctionParameter(typeName: TypeName(name: "ConversationApiResponse", attributes: ["escaping": [Attribute(name: "escaping")]]))
        XCTAssertEqual(sut.unwrappedTypeName, "ConversationApiResponse")
    }

    func test_initializesWithInoutTrue() {
        let sut = FunctionParameter(typeName: TypeName(name: "Bar"), isInout: true)
        XCTAssertTrue(sut.inout)
    }

    func test_equals_whenSameItems() {
        let sut = FunctionParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertEqual(sut, FunctionParameter(name: "foo", typeName: TypeName(name: "Int")))
    }

    func test_differs_whenDifferentItems() {
        let sut = FunctionParameter(name: "foo", typeName: TypeName(name: "Int"))
        XCTAssertNotEqual(sut, FunctionParameter(name: "bar", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, FunctionParameter(argumentLabel: "bar", name: "foo", typeName: TypeName(name: "Int")))
        XCTAssertNotEqual(sut, FunctionParameter(name: "foo", typeName: TypeName(name: "String")))
        XCTAssertNotEqual(sut, FunctionParameter(name: "foo", typeName: TypeName(name: "String"), isInout: true))
    }
}
