import PathKit
import XCTest
@testable import SourceryKit

final class SwiftSyntaxParserProtocolTests: XCTestCase {
    var sut: SwiftSyntaxParser!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_protocol_whenOneAssociatedType() {
        let code = """
        protocol Foo {
            associatedtype Bar
        }
        """
        XCTAssertEqual(try sut.parseAssociatedTypes(code), [AssociatedType(name: "Bar")])
    }

    func test_protocol_whenMultipleAssociatedTypes() {
        let code = """
        protocol Foo {
            associatedtype Bar
            associatedtype Baz
        }
        """
        XCTAssertEqual(
            try sut.parseAssociatedTypes(code).sorted { $0.name < $1.name },
            [AssociatedType(name: "Bar"), AssociatedType(name: "Baz")]
        )
    }

    func test_protocol_whenAssociatedTypeConstrainedToUnknownType() {
        let code = """
        protocol Foo {
            associatedtype Bar: Codable
        }
        """
        XCTAssertEqual(
            try sut.parseAssociatedTypes(code),
            [AssociatedType(name: "Bar", typeName: TypeName(name: "Codable"))]
        )
    }

    func test_protocol_whenAssociatedTypeConstrainedToKnownType() {
        let code = """
        protocol A {}
        protocol Foo {
            associatedtype Bar: A
        }
        """
        XCTAssertEqual(
            try sut.parseAssociatedTypes(code),
            [AssociatedType(name: "Bar", typeName: TypeName(name: "A"))]
        )
    }

    func test_protocol_whenAssociatedTypeConstrainedToCompositeType() throws {
        let parsed = try sut.parseAssociatedTypes("""
        protocol Foo {
            associatedtype Bar: Encodable & Decodable
        }
        """).first

        XCTAssertEqual(parsed, AssociatedType(
            name: "Bar",
            typeName: TypeName(name: "Encodable & Decodable")
        ))
        XCTAssertEqual(parsed?.type, ProtocolComposition(
            parent: SourceryProtocol(name: "Foo"),
            inheritedTypes: ["Encodable", "Decodable"],
            composedTypeNames: [TypeName(name: "Encodable"), TypeName(name: "Decodable")]
        ))
    }
}

private extension SwiftSyntaxParser {
    func parseAssociatedTypes(_ code: String) throws -> [AssociatedType] {
        parse(code)
            .types
            .compactMap { $0 as? SourceryProtocol }
            .flatMap(\.associatedTypes.values)
    }
}
