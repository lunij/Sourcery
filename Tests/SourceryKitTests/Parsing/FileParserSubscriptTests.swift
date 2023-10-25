import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class FileParserSubscriptTests: XCTestCase {
    private func parse(_ code: String) throws -> [Type] {
        try FileParserSyntax(contents: code).parse().types
    }

    func test_extractsSubscripts() throws {
        let subscripts = try parse("""
        class Foo {
            final private subscript(_ index: Int, a: String) -> Int {
                get { return 0 }
                set { do {} }
            }
            public private(set) subscript(b b: Int) -> String {
                get { return \"\"}
                set { }
            }
        }
        """).first?.subscripts

        XCTAssertEqual(
            subscripts?.first,
            Subscript(
                parameters: [
                    MethodParameter(argumentLabel: nil, name: "index", typeName: TypeName(name: "Int")),
                    MethodParameter(argumentLabel: "a", name: "a", typeName: TypeName(name: "String"))
                ],
                returnTypeName: TypeName(name: "Int"),
                accessLevel: (.private, .private),
                modifiers: [
                    Modifier(name: "final"),
                    Modifier(name: "private")
                ],
                annotations: [:],
                definedInTypeName: TypeName(name: "Foo")
            )
        )

        XCTAssertEqual(
            subscripts?.last,
            Subscript(
                parameters: [
                    MethodParameter(argumentLabel: "b", name: "b", typeName: TypeName(name: "Int"))
                ],
                returnTypeName: TypeName(name: "String"),
                accessLevel: (.public, .private),
                modifiers: [
                    Modifier(name: "public"),
                    Modifier(name: "private", detail: "set")
                ],
                annotations: [:],
                definedInTypeName: TypeName(name: "Foo")
            )
        )
    }

    func test_extractsSubscriptIsMutableState() throws {
        let subscripts = try parse("""
        protocol Subscript: AnyObject {
          subscript(arg1: String, arg2: Int) -> Bool { get set }
          subscript(with arg1: String, and arg2: Int) -> String { get }
        }
        """).first?.subscripts

        XCTAssertEqual(subscripts?.first?.isMutable, true)
        XCTAssertEqual(subscripts?.last?.isMutable, false)

        XCTAssertEqual(subscripts?.first?.readAccess, "internal")
        XCTAssertEqual(subscripts?.first?.writeAccess, "internal")

        XCTAssertEqual(subscripts?.last?.readAccess, "internal")
        XCTAssertEqual(subscripts?.last?.writeAccess, "")
    }

    func test_extractsSubscriptAnnotations() throws {
        let subscripts = try parse("""
        //sourcery: thisIsClass
        class Foo {
          // sourcery: thisIsSubscript
          subscript(/* sourcery: thisIsSubscriptParam */a: Int) -> Int { return 0 }
        }
        """)
            .first?.subscripts

        let subscriptAnnotations = subscripts?.first?.annotations
        XCTAssertEqual(subscriptAnnotations, ["thisIsSubscript": NSNumber(value: true)])

        let paramAnnotations = subscripts?.first?.parameters.first?.annotations
        XCTAssertEqual(paramAnnotations, ["thisIsSubscriptParam": NSNumber(value: true)])
    }
}
