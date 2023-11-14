import XCTest
import Foundation
@testable import SourceryKit

class MethodTests: XCTestCase {
    var sut: SourceryMethod!

    override func setUp() {
        sut = Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: [FunctionParameter(name: "some", typeName: TypeName(name: "Int"))], definedInTypeName: TypeName(name: "Bar"))
    }

    func test_reportsShortName() {
        XCTAssertEqual(sut.shortName, "foo")
    }

    func test_reportsDefinedInTypeName() {
        XCTAssertEqual(Method(name: "foo()", definedInTypeName: TypeName(name: "BarAlias", actualTypeName: TypeName(name: "Bar"))).definedInTypeName, TypeName(name: "BarAlias"))
        XCTAssertEqual(Method(name: "foo()", definedInTypeName: TypeName(name: "Foo")).definedInTypeName, TypeName(name: "Foo"))
    }

    func test_reportsActualDefinedInTypeName() {
        XCTAssertEqual(Method(name: "foo()", definedInTypeName: TypeName(name: "BarAlias", actualTypeName: TypeName(name: "Bar"))).actualDefinedInTypeName, TypeName(name: "Bar"))
    }

    func test_reportsIsDeinitializer() {
        XCTAssertFalse(sut.isDeinitializer)
        XCTAssertFalse(Method(name: "deinitObjects() {}").isDeinitializer)
        XCTAssertTrue(Method(name: "deinit").isDeinitializer)
    }

    func test_reportsIsInitializer() {
        XCTAssertFalse(sut.isInitializer)
        XCTAssertTrue(Method(name: "init()").isInitializer)
    }

    func test_reportsFailableInitializerReturnTypeAsOptional() {
        XCTAssertTrue(Method(name: "init()", isFailableInitializer: true).isOptionalReturnType)
    }

    func test_reportsGenericMethod() {
        XCTAssertTrue(Method(name: "foo<T>()").isGeneric)
        XCTAssertFalse(Method(name: "foo()").isGeneric)
    }

    func test_equals_whenSameItems() {
        XCTAssertEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: [FunctionParameter(name: "some", typeName: TypeName(name: "Int"))], definedInTypeName: TypeName(name: "Bar")))
    }

    func test_differs_whenDifferentItems() {
        let parameters = [FunctionParameter(name: "some", typeName: TypeName(name: "Int"))]
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: [FunctionParameter(name: "some", typeName: TypeName(name: "Int"))], definedInTypeName: TypeName(name: "Baz")))
        XCTAssertNotEqual(sut, Method(name: "bar(some: Int)", selectorName: "bar(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: [], returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "String"), accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), throws: true, accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .public, isStatic: false, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: true, isClass: false, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: false, isClass: true, isFailableInitializer: false, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: true, annotations: [:]))
        XCTAssertNotEqual(sut, Method(name: "foo(some: Int)", selectorName: "foo(some:)", parameters: parameters, returnTypeName: TypeName(name: "Void"), accessLevel: .internal, isStatic: false, isClass: false, isFailableInitializer: false, annotations: ["some": NSNumber(value: true)]))
    }
}
