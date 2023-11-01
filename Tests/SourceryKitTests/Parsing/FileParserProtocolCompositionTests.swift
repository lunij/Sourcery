import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class FileParserProtocolCompositionTests: XCTestCase {
    private func parse(_ code: String) throws -> [Type] {
        try SwiftSyntaxParser(contents: code).parse().types
    }

    func test_extractsProtocolCompositions() throws {
        let types = try parse("""
        protocol Foo {
            func fooDo()
        }

        protocol Bar {
            var bar: String { get }
        }

        typealias FooBar = Foo & Bar
        """)
        let protocolComp = types.first(where: { $0 is ProtocolComposition }) as? ProtocolComposition

        XCTAssertEqual(
            protocolComp,
            ProtocolComposition(
                name: "FooBar",
                inheritedTypes: ["Foo", "Bar"],
                composedTypeNames: [
                    TypeName("Foo"),
                    TypeName("Bar")
                ],
                composedTypes: [
                    SourceryProtocol(name: "Foo"),
                    SourceryProtocol(name: "Bar")
                ]
            )
        )
    }

    func test_extractsAnnotationsOnProtocolComposition() throws {
        let types = try parse("""
        protocol Foo {
            func fooDo()
        }

        protocol Bar {
            var bar: String { get }
        }

        // sourcery: TestAnnotation
        typealias FooBar = Foo & Bar
        """)
        let protocolComp = types.first(where: { $0 is ProtocolComposition }) as? ProtocolComposition

        XCTAssertEqual(protocolComp?.annotations, ["TestAnnotation": NSNumber(true)])
    }
}
