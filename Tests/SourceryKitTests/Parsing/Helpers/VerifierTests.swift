import SourceryUtils
import XCTest
@testable import SourceryFramework
@testable import SourceryKit
@testable import SourceryRuntime

class VerifierTests: XCTestCase {
    func test_allowsEmptyStrings() {
        XCTAssertEqual(Verifier.canParse(content: "", path: Path("/"), generationMarker: Sourcery.generationMarker), Verifier.Result.approved)
    }

    func test_rejectsFilesGeneratedBySourcery() {
        let content = Sourcery.generationMarker + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/"), generationMarker: Sourcery.generationMarker), Verifier.Result.isCodeGenerated)
    }

    func test_rejectsFilesGeneratedBySourceryWhenAForceParseExtensionIsDefinedButDoesNotMatchFile() {
        let content = Sourcery.generationMarker + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/file.swift"), generationMarker: Sourcery.generationMarker, forceParse: ["toparse"]), Verifier.Result.isCodeGenerated)
    }

    func test_doesNotRejectFilesGeneratedBySourceryButThatWeWantToForceTheParsingFor() {
        let content = Sourcery.generationMarker + "\n something\n is\n there"

        XCTAssertEqual(Verifier.canParse(content: content, path: Path("/file.toparse.swift"), generationMarker: Sourcery.generationMarker, forceParse: ["toparse"]), Verifier.Result.approved)
    }

    func test_rejectsFileContainingConflictMarker() {
        let content = ["\n<<<<<\n", "\n>>>>>\n"]

        content.forEach { XCTAssertEqual(Verifier.canParse(content: $0, path: Path("/"), generationMarker: Sourcery.generationMarker), Verifier.Result.containsConflictMarkers) }
    }
}
