import SwiftParser
import SwiftSyntax
import XCTest
@testable import SourceryKit

class GetAnnotationUseCaseTests: XCTestCase {
    var sut: GetAnnotationUseCase!

    override func setUp() {
        super.setUp()

        let content = """
        // sourcery: skipEquality
        class Foobar {}
        """

        sut = .init(GetAnnotationUseCase(
            content: content,
            annotationParser: AnnotationParser(),
            sourceLocationConverter: SourceLocationConverter(fileName: "fakeFileName", tree: content.parse())
        ))
    }

    func test_returnsAnnotationsFromSwiftSyntax() {
        let declaration = ClassDeclSyntax(
            leadingTrivia: [
                .lineComment("// sourcery: skipEquality"),
                .newlines(1)
            ],
            name: .identifier("Foo"),
            memberBlock: .init(members: [])
        )
        let annotations = sut.annotations(from: declaration)
        XCTAssertEqual(annotations, ["skipEquality": true])
    }
}

private extension String {
    func parse() -> SyntaxProtocol {
        Parser.parse(source: self)
    }
}
