import XCTest
@testable import SourceryLib
@testable import SourceryRuntime

class EnumTests: XCTestCase {
    var sut: Enum!
    let variable = Variable(name: "variable", typeName: TypeName(name: "Int"), accessLevel: (read: .public, write: .internal), isComputed: false, definedInTypeName: TypeName(name: "Foo"))

    override func setUp() {
        super.setUp()
        sut = Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")])
    }

    func test_reportsKindAsEnum() {
        XCTAssertEqual(sut?.kind, "enum")
    }

    func test_doesNotHaveAssociatedValues() {
        XCTAssertFalse(sut.hasAssociatedValues)
    }

    func test_supportsAssociatedValues() {
        let sut = Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA", associatedValues: [AssociatedValue(name: nil, typeName: TypeName(name: "Int"))]), EnumCase(name: "CaseB")])

        XCTAssertTrue(sut.hasAssociatedValues)
    }

    func test_equals_whenSameItems() {
        XCTAssertEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")]))
    }

    func test_differs_whenDifferentItems() {
        XCTAssertNotEqual(sut, Enum(name: "Bar", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")], variables: [variable]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .public, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: true, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [EnumCase(name: "CaseA"), EnumCase(name: "CaseB")]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseB")]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseB", associatedValues: [AssociatedValue(name: nil, typeName: TypeName(name: "Int"))])]))
        XCTAssertNotEqual(sut, Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [EnumCase(name: "CaseB")]))
    }
}
