import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class VerifierTests: XCTestCase {
    func test_allowsEmptyStrings() {
        XCTAssertEqual(Verifier.canParse(content: "", path: Path("/")), Verifier.Result.approved)
    }

    func test_rejectsFilesGeneratedBySourcery() {
        let content = .generatedHeader + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/")), Verifier.Result.isCodeGenerated)
    }

    func test_rejectsFilesGeneratedBySourceryWhenAForceParseExtensionIsDefinedButDoesNotMatchFile() {
        let content = .generatedHeader + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/file.swift"), forceParse: ["toparse"]), Verifier.Result.isCodeGenerated)
    }

    func test_doesNotRejectFilesGeneratedBySourceryButThatWeWantToForceTheParsingFor() {
        let content = .generatedHeader + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/file.toparse.swift"), forceParse: ["toparse"]), Verifier.Result.approved)
    }

    func test_rejectsFileContainingConflictMarker() {
        let content = ["\n<<<<<\n", "\n>>>>>\n"]

        content.forEach { XCTAssertEqual(Verifier.canParse(content: $0, path: Path("/")), Verifier.Result.containsConflictMarkers) }
    }
}
