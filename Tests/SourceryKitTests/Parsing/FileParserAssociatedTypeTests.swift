import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

final class FileParserAssociatedTypeTests: XCTestCase {
    private func associatedType(_ code: String, protocolName: String? = nil) throws -> [AssociatedType] {
        try makeParser(for: code)
            .parse()
            .types
            .compactMap { $0 as? SourceryProtocol }
            .first { protocolName != nil ? $0.name == protocolName : true }?
            .associatedTypes
            .values
            .map { $0 } ?? []
    }

    func test_protocol_whenOneAssociatedType() {
        let code = """
        protocol Foo {
            associatedtype Bar
        }
        """
        XCTAssertEqual(try associatedType(code), [AssociatedType(name: "Bar")])
    }

    func test_protocol_whenMultipleAssociatedTypes() {
        let code = """
        protocol Foo {
            associatedtype Bar
            associatedtype Baz
        }
        """
        XCTAssertEqual(
            try associatedType(code).sorted(by: { $0.name < $1.name }),
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
            try associatedType(code),
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
            try associatedType(code, protocolName: "Foo"),
            [AssociatedType(name: "Bar", typeName: TypeName(name: "A"))]
        )
    }

    func test_protocol_whenAssociatedTypeConstrainedToCompositeType() throws {
        let parsed = try associatedType("""
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
