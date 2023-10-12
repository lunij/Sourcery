import PathKit
import XCTest
@testable import SourceryKit

class SourceryPerformanceTests: XCTestCase {
    let outputDir: Path = {
        Path.cleanTemporaryDir(name: "SourceryPerformance")
    }()
    var output: Output { .init(outputDir) }

    func testParsingPerformanceOnCleanRun() {
        _ = try? Path.cachesDir(sourcePath: Stubs.sourceForPerformance, basePath: nil).delete()

        measure {
            _ = try? Sourcery(cacheDisabled: true).processFiles(
                .sources(Paths(include: [Stubs.sourceForPerformance])),
                usingTemplates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
                output: output
            )
        }
    }

    func testParsingPerformanceOnSubsequentRun() {
        _ = try? Path.cachesDir(sourcePath: Stubs.sourceForPerformance, basePath: nil).delete()
        _ = try? Sourcery().processFiles(
            .sources(Paths(include: [Stubs.sourceForPerformance])),
            usingTemplates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
            output: output
        )

        measure {
            _ = try? Sourcery().processFiles(
                .sources(Paths(include: [Stubs.sourceForPerformance])),
                usingTemplates: Paths(include: [Stubs.templateDirectory + Path("Basic.stencil")]),
                output: output
            )
        }
    }
}
