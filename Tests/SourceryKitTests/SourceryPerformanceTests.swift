import PathKit
import XCTest
@testable import SourceryKit

class SourceryPerformanceTests: XCTestCase {
    var output: Path!

    override func setUpWithError() throws {
        try super.setUpWithError()
        output = try Path.createTestDirectory(suffixed: "SourceryPerformanceTests")
    }

    func testParsingPerformanceOnCleanRun() {
        let sourceFile = SourceFile(path: Stubs.sourceForPerformance)
        _ = try? Path.cachesDir(sourcePath: sourceFile.path, basePath: nil).delete()

        measure {
            _ = try? Sourcery().processConfiguration(.stub(
                sources: [sourceFile],
                templates: [Stubs.templateDirectory + Path("Basic.stencil")],
                output: output,
                cacheDisabled: true
            ))
        }
    }

    func testParsingPerformanceOnSubsequentRun() {
        let sourceFile = SourceFile(path: Stubs.sourceForPerformance)
        _ = try? Path.cachesDir(sourcePath: sourceFile.path, basePath: nil).delete()
        _ = try? Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [Stubs.templateDirectory + Path("Basic.stencil")],
            output: output
        ))

        measure {
            _ = try? Sourcery().processConfiguration(.stub(
                sources: [sourceFile],
                templates: [Stubs.templateDirectory + Path("Basic.stencil")],
                output: output
            ))
        }
    }
}
