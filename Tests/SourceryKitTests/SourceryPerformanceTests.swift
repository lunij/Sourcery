import PathKit
import XCTest
@testable import SourceryKit

class SourceryPerformanceTests: XCTestCase {
    var output: Output!

    override func setUpWithError() throws {
        try super.setUpWithError()
        output = try .init(.createTestDirectory(suffixed: "SourceryPerformanceTests"))
    }

    func testParsingPerformanceOnCleanRun() {
        _ = try? Path.cachesDir(sourcePath: Stubs.sourceForPerformance, basePath: nil).delete()

        measure {
            _ = try? Sourcery(cacheDisabled: true).processConfiguration(.stub(
                sources: .paths(Paths(include: [Stubs.sourceForPerformance])),
                templates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
                output: output
            ))
        }
    }

    func testParsingPerformanceOnSubsequentRun() {
        _ = try? Path.cachesDir(sourcePath: Stubs.sourceForPerformance, basePath: nil).delete()
        _ = try? Sourcery().processConfiguration(.stub(
            sources: .paths(Paths(include: [Stubs.sourceForPerformance])),
            templates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
            output: output
        ))

        measure {
            _ = try? Sourcery().processConfiguration(.stub(
                sources: .paths(Paths(include: [Stubs.sourceForPerformance])),
                templates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
                output: output
            ))
        }
    }
}
