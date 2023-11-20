import SwiftParser
import SwiftSyntax
import XCTest
@testable import SourceryKit

class GetAnnotationUseCaseTests: XCTestCase {
    var sut: GetAnnotationUseCase!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_returnsAnnotations_whenClass() throws {
        let syntax = """
        // sourcery: trivia
        class Foo {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(ClassDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }

    func test_returnsAnnotations_whenEnum() throws {
        let syntax = """
        // sourcery: trivia
        enum Foo {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(EnumDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }

    func test_returnsAnnotations_whenEnumCase_andLineComment() throws {
        let syntax = """
        enum Foo {
            // sourcery: trivia
            case bar
        }
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax)
        let annotations = sut.parseAnnotations(from: declSyntax).map(\.annotations)
        XCTAssertEqual(annotations, [["trivia": true]])
    }

    func test_returnsAnnotations_whenEnumCase_andBlockComment() throws {
        let syntax = """
        enum Foo {
            /* sourcery: trivia */
            case bar
        }
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax)
        let annotations = sut.parseAnnotations(from: declSyntax).map(\.annotations)
        XCTAssertEqual(annotations, [["trivia": true]])
    }

    func test_returnsAnnotations_whenEnumCase_andInlineBlockComment() throws {
        let syntax = """
        enum Foo {
            /* sourcery: trivia */ case bar
        }
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax)
        let annotations = sut.parseAnnotations(from: declSyntax).map(\.annotations)
        XCTAssertEqual(annotations, [["trivia": true]])
    }

    func test_returnsAnnotations_whenEnumCasesInlined_andInlineBlockComment() throws {
        let syntax = """
        enum Foo {
            case /* sourcery: 1st trivia */ first, /* sourcery: 2nd trivia */ second, third
        }
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax)
        let annotations = sut.parseAnnotations(from: declSyntax).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["1st trivia": true],
            ["2nd trivia": true],
            [:]
        ])
    }

    func test_returnsAnnotations_whenEnumCaseAssociatedValues_andLineComment() throws {
        let syntax = """
        enum Foo {
            case bar(
                // sourcery: first trivia
                String,
                // sourcery: second trivia
                Int
            )
        }
        """.parse()
        let parameterClause = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax?.elements.first?.parameterClause)
        let annotations = sut.parseAnnotations(from: parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenEnumCaseAssociatedValues_andBlockComment() throws {
        let syntax = """
        enum Foo {
            case bar(
                /* sourcery: first trivia */ 
                String,
                /* sourcery: second trivia */ 
                Int
            )
        }
        """.parse()
        let parameterClause = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax?.elements.first?.parameterClause)
        let annotations = sut.parseAnnotations(from: parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenEnumCaseAssociatedValues_andInlineBlockComment() throws {
        let syntax = """
        enum Foo {
            case bar(
                /* sourcery: first trivia */ String,
                /* sourcery: second trivia */ Int
            )
        }
        """.parse()
        let parameterClause = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax?.elements.first?.parameterClause)
        let annotations = sut.parseAnnotations(from: parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenEnumCaseAssociatedValues_andInlineBlockComment_andSquashed() throws {
        let syntax = """
        enum Foo {
            case bar(/* sourcery: first trivia */String, /* sourcery: second trivia */Int)
        }
        """.parse()
        let parameterClause = try XCTUnwrap(syntax.first(EnumDeclSyntax.self)?.firstCaseDeclSyntax?.elements.first?.parameterClause)
        let annotations = sut.parseAnnotations(from: parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenExtension() throws {
        let syntax = """
        // sourcery: trivia
        extension String {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(ExtensionDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }

    func test_returnsAnnotations_whenExtension_andModifier() throws {
        let syntax = """
        // sourcery: trivia
        public extension String {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(ExtensionDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }

    func test_returnsAnnotations_whenFunction() throws {
        let syntax = """
        // sourcery: trivia
        func foo() {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(FunctionDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }

    func test_returnsAnnotations_whenFunctionParameter_andLineComment() throws {
        let syntax = """
        func foo(
            // sourcery: first trivia
            first: String,
            // sourcery: second trivia
            second: String
        ) {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(FunctionDeclSyntax.self))
        
        let annotations = sut.parseAnnotations(from: declSyntax.signature.parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenFunctionParameter_andBlockComment() throws {
        let syntax = """
        func foo(
            /* sourcery: first trivia */
            first: String,
            /* sourcery: second trivia */
            second: String
        ) {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(FunctionDeclSyntax.self))
        
        let annotations = sut.parseAnnotations(from: declSyntax.signature.parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenFunctionParameter_andInlineBlockComment() throws {
        let syntax = """
        func foo(
            /* sourcery: first trivia */ first: String,
            /* sourcery: second trivia */ second: String
        ) {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(FunctionDeclSyntax.self))

        let annotations = sut.parseAnnotations(from: declSyntax.signature.parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true]
        ])
    }

    func test_returnsAnnotations_whenFunctionParameter_andInlineBlockComment_andSquashed() throws {
        let syntax = """
        func foo(/* sourcery: first trivia */first: String, /* sourcery: second trivia */second: String, third: String) {}
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(FunctionDeclSyntax.self))
        
        let annotations = sut.parseAnnotations(from: declSyntax.signature.parameterClause).map(\.annotations)
        XCTAssertEqual(annotations, [
            ["first trivia": true],
            ["second trivia": true],
            [:]
        ])
    }

    func test_returnsAnnotations_whenVariable() throws {
        let syntax = """
        // sourcery: trivia
        var foobar: String
        """.parse()
        let declSyntax = try XCTUnwrap(syntax.first(VariableDeclSyntax.self))
        let annotations = sut.parseAnnotations(from: declSyntax)
        XCTAssertEqual(annotations, ["trivia": true])
    }
}

private extension String {
    func parse() -> SourceFileSyntax {
        Parser.parse(source: self)
    }
}

private extension SourceFileSyntax {
    func first<S: SyntaxProtocol>(_ syntaxType: S.Type) -> S? {
        statements.first?.item.as(syntaxType)
    }
}

private extension EnumDeclSyntax {
    var firstCaseDeclSyntax: EnumCaseDeclSyntax? {
        memberBlock.members.first?.decl.as(EnumCaseDeclSyntax.self)
    }
}
