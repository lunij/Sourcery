
import SourceryRuntime
import XCTest
@testable import SourceryKit

class FileParserTypeNameTests: XCTestCase {
    func test_isOptional() {
        XCTAssertEqual("Int?".typeName.isOptional, true)
        XCTAssertEqual("Int!".typeName.isOptional, true)
        XCTAssertEqual("Optional<Int>".typeName.isOptional, true)

        XCTAssertEqual("() -> ()".typeName.isOptional, false)
        XCTAssertEqual("() -> ()?".typeName.isOptional, false)
        XCTAssertEqual("Optional<()> -> ()".typeName.isOptional, false)
        XCTAssertEqual("(() -> ()?)".typeName.isOptional, false)

        XCTAssertEqual("(() -> ())?".typeName.isOptional, true)
        XCTAssertEqual("Optional<() -> ()>".typeName.isOptional, true)
    }

    func test_isImplicitlyUnwrappedOptional() {
        XCTAssertEqual("Int?".typeName.isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual("Int!".typeName.isImplicitlyUnwrappedOptional, true)
        XCTAssertEqual("Optional<Int>".typeName.isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual("() -> ()!".typeName.isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual("(() -> ()!)".typeName.isImplicitlyUnwrappedOptional, false)
        XCTAssertEqual("(() -> ())!".typeName.isImplicitlyUnwrappedOptional, true)
    }

    func test_unwrappedTypeName() {
        XCTAssertEqual("Int?".typeName.unwrappedTypeName, "Int")
        XCTAssertEqual("Int!".typeName.unwrappedTypeName, "Int")
        XCTAssertEqual("Optional<Int>".typeName.unwrappedTypeName, "Int")

        XCTAssertEqual("inout String".typeName.unwrappedTypeName, "String")

        XCTAssertEqual("(Int)".typeName.unwrappedTypeName, "Int")
        XCTAssertEqual("(Int)?".typeName.unwrappedTypeName, "Int")
        XCTAssertEqual("(Int, Int)".typeName.unwrappedTypeName, "(Int, Int)")
        XCTAssertEqual("(Int)".typeName.unwrappedTypeName, "Int")
        XCTAssertEqual("((Int, Int))".typeName.unwrappedTypeName, "(Int, Int)")
        XCTAssertEqual("((Int, Int) -> ())".typeName.unwrappedTypeName, "(Int, Int) -> ()")

        XCTAssertEqual("@escaping (@escaping ()->())->()".typeName.unwrappedTypeName, "(@escaping () -> ()) -> ()")
    }

    func test_isTuple() {
        XCTAssertEqual("(Int, Int)".typeName.isTuple, true)
        XCTAssertEqual("(Int, Int)?".typeName.isTuple, true)
        XCTAssertEqual("(Int)".typeName.isTuple, false)
        XCTAssertEqual("Int".typeName.isTuple, false)
        XCTAssertEqual("(Int) -> (Int)".typeName.isTuple, false)
        XCTAssertEqual("(Int, Int) -> (Int)".typeName.isTuple, false)
        XCTAssertEqual("(Int, (Int, Int) -> (Int))".typeName.isTuple, true)
        XCTAssertEqual("(Int, (Int, Int))".typeName.isTuple, true)
        XCTAssertEqual("(Int, (Int) -> (Int -> Int))".typeName.isTuple, true)
    }

    func test_isArray_whenArray() {
        XCTAssertEqual("Array<Int>".typeName.isArray, true)
        XCTAssertEqual("[Int]".typeName.isArray, true)
        XCTAssertEqual("[[Int]]".typeName.isArray, true)
        XCTAssertEqual("[[Int: Int]]".typeName.isArray, true)
    }

    func test_isArray_whenNoArray() {
        XCTAssertEqual("[Int: Int]".typeName.isArray, false)
        XCTAssertEqual("[[Int]: [Int]]".typeName.isArray, false)
        XCTAssertEqual("[Int: [Int: Int]]".typeName.isArray, false)
    }

    func test_isDictionary_whenDictionary() {
        XCTAssertEqual("Dictionary<Int, Int>".typeName.isDictionary, true)
        XCTAssertEqual("[Int: Int]".typeName.isDictionary, true)
        XCTAssertEqual("[[Int]: [Int]]".typeName.isDictionary, true)
        XCTAssertEqual("[Int: [Int: Int]]".typeName.isDictionary, true)
    }

    func test_isDictionary_whenNoDictionary() {
        XCTAssertEqual("[Int]".typeName.isDictionary, false)
        XCTAssertEqual("[[Int]]".typeName.isDictionary, false)
        XCTAssertEqual("[[Int: Int]]".typeName.isDictionary, false)
    }

    func test_isClosure_whenClosure() {
        XCTAssertEqual("() -> ()".typeName.isClosure, true)
        XCTAssertEqual("(() -> ())?".typeName.isClosure, true)
        XCTAssertEqual("(Int, Int) -> ()".typeName.isClosure, true)
        XCTAssertEqual("() -> (Int, Int)".typeName.isClosure, true)
        XCTAssertEqual("() -> (Int) -> (Int)".typeName.isClosure, true)
        XCTAssertEqual("((Int) -> (Int)) -> ()".typeName.isClosure, true)
        XCTAssertEqual("(Foo<String>) -> Bool".typeName.isClosure, true)
        XCTAssertEqual("(Int) -> Foo<Bool>".typeName.isClosure, true)
        XCTAssertEqual("(Foo<String>) -> Foo<Bool>".typeName.isClosure, true)
        XCTAssertEqual("(Foo) -> Bar".typeNameFromTypealias.isClosure, true)
        XCTAssertEqual("(Foo) -> Bar & Baz".typeNameFromTypealias.isClosure, true)
    }

    func test_isClosure_whenNoClosure() {
        XCTAssertEqual("((Int, Int) -> (), Int)".typeName.isClosure, false)
        XCTAssertEqual("Foo<() -> ()>".typeName.isClosure, false)
        XCTAssertEqual("Foo<(String) -> Bool>".typeName.isClosure, false)
        XCTAssertEqual("Foo<(String) -> Bool?>".typeName.isClosure, false)
        XCTAssertEqual("Foo<(Bar<String>) -> Bool>".typeName.isClosure, false)
        XCTAssertEqual("Foo<(Bar<String>) -> Bar<Bool>>".typeName.isClosure, false)
    }

    func test_ordersAttributesAlphabetically() {
        XCTAssertEqual("@escaping @autoclosure () -> String".typeName.asSource, "@autoclosure @escaping () -> String")
        XCTAssertEqual("@escaping @autoclosure () -> String".typeName.description, "@autoclosure @escaping () -> String")
    }
}

private extension String {
    var typeName: TypeName {
        let wrappedCode = """
        struct Wrapper {
            var myFoo: \(self)
        }
        """
        let result = SwiftSyntaxParser().parse(wrappedCode)
        let variable = result.types.first?.variables.first
        return variable?.typeName ?? TypeName(name: "")
    }

    var typeNameFromTypealias: TypeName {
        let wrappedCode = "typealias Wrapper = \(self)"
        let result = SwiftSyntaxParser().parse(wrappedCode)
        return result.typealiases.first?.typeName ?? TypeName(name: "")
    }
}
