import SwiftSyntax
import XCTest
@testable import SourceryKit

class GetDocumentationUseCaseTests: XCTestCase {
    var sut: GetDocumentationUseCase!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_returnsDocumentationFromSwiftSyntax() {
        let declaration = ClassDeclSyntax(
            leadingTrivia: [
                .docLineComment("/// documentation 1"),
                .newlines(1),
                .lineComment("// comment 1"),
                .newlines(1),
                .docLineComment("/// documentation 2"),
                .newlines(1),
                .lineComment("// comment 2"),
                .newlines(1),
                .docLineComment("/// documentation 3")
            ],
            name: .identifier("Foo"),
            memberBlock: .init(members: [])
        )
        let documentation = sut.documentation(from: declaration)
        XCTAssertEqual(documentation, [
            "/// documentation 1",
            "/// documentation 2",
            "/// documentation 3"
        ])
    }
}
