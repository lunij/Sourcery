import XCTest
@testable import SourceryRuntime

class VariableTests: XCTestCase {
    var sut: Variable!

    override func setUp() {
        sut = Variable(name: "variable", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Foo"))
    }

    func test_hasProperDefinedInTypeName() {
        XCTAssertEqual(sut.definedInTypeName, TypeName(name: "Foo"))
    }

    func test_hasProperReadAccess() {
        XCTAssertEqual(sut.readAccess, AccessLevel.public.rawValue)
    }

    func test_hasProperWriteAccess() {
        XCTAssertEqual(sut.writeAccess, AccessLevel.internal.rawValue)
    }

    func test_equals_whenSameItems() {
        XCTAssertEqual(sut, Variable(name: "variable", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Foo")))
    }

    func test_differs_whenDifferentItems() {
        XCTAssertNotEqual(sut, Variable(name: "other", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Variable(name: "variable", typeName: TypeName(name: "Float"), accessLevel: (read: .public, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Variable(name: "other", typeName: TypeName(name: "Int"), accessLevel: (read: .internal, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Variable(name: "other", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .public), isComputed: true, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Variable(name: "other", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: false, definedInTypeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Variable(name: "variable", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: true, definedInTypeName: TypeName(name: "Bar")))
    }
}
