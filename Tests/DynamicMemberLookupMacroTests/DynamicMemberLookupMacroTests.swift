import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import DynamicMemberLookupMacro

final class DynamicMemberLookupMacroTests: XCTestCase {
    private let sut = ["DynamicMemberLookup": DynamicMemberLookupMacro.self]

    func test_macro() {
        assertMacroExpansion(
            """
            @DynamicMemberLookup
            public struct Foobar {
                let storedProperty: String

                var computedProperty: String {
                    "fakeValue"
                }

                func foo(bar: String) -> String {
                    "fakeValue"
                }
            }
            """,
            expandedSource: """
            @dynamicMemberLookup
            public struct Foobar {
                let storedProperty: String

                var computedProperty: String {
                    "fakeValue"
                }

                func foo(bar: String) -> String {
                    "fakeValue"
                }

                public subscript(dynamicMember member: String) -> Any? {
                    switch member {
                    case "computedProperty": computedProperty
                    case "storedProperty": storedProperty
                    default: nil
                    }
                }
            }
            """,
            macros: sut
        )
    }

    func test_macro_whenAttachedToNonProtocol() throws {
        let declaration = "struct Foo {}"
        assertMacroExpansion(
            """
            @DynamicMemberLookup
            \(declaration)
            """,
            expandedSource: """
            \(declaration)
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Mock can only be applied to a protocol", line: 1, column: 1)
            ],
            macros: sut
        )
    }
}
