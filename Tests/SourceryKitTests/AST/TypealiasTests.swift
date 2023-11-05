import XCTest
@testable import SourceryKit

class TypealiasTests: XCTestCase {
    var sut: Typealias!

    override func setUp() {
        sut = Typealias(aliasName: "Foo", typeName: TypeName(name: "Bar"))
    }

    func test_reportsName_whenNoParentType() {
        XCTAssertEqual(sut.name, "Foo")
    }

    func test_reportsName_whenParentType() {
        sut?.parent = Type(name: "FooBar", parent: Type(name: "Parent"))

        XCTAssertEqual(sut.name, "Parent.FooBar.Foo")
    }

    func test_equals_whenSameItems() {
        XCTAssertEqual(sut, Typealias(aliasName: "Foo", typeName: TypeName(name: "Bar")))
    }

    func test_diffes_whenDifferentItems() {
        XCTAssertNotEqual(sut, Typealias(aliasName: "Foo", typeName: TypeName(name: "Foo")))
        XCTAssertNotEqual(sut, Typealias(aliasName: "Bar", typeName: TypeName(name: "Bar")))
        XCTAssertNotEqual(sut, Typealias(aliasName: "Bar", typeName: TypeName(name: "Bar"), parent: Type(name: "Parent")))
    }
}
