import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class DryOutputStencilTemplateTests: XCTestCase {
    func test_hasNoStdoutJsonOutputIfIsDryRunEqualFalse() {
        var outputDir = Path("/tmp")
        outputDir = Stubs.cleanTemporarySourceryDir()

        let templatePath = Stubs.templateDirectory + Path("Include.stencil")
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: Output(outputDir),
                isDryRun: false
            )
        )
        XCTAssertNil(outputInterceptor.result)
    }

    func test_includesPartialTemplates() {
        var outputDir = Path("/tmp")
        outputDir = Stubs.cleanTemporarySourceryDir()

        let templatePath = Stubs.templateDirectory + Path("Include.stencil")
        let expectedResult = """
        // Generated using Sourcery

        partial template content

        """

        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: Output(outputDir),
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_supportsDifferentWaysForCodeGeneration() {
        let templatePath = Stubs.templateDirectory + Path("GenerationWays.stencil")
        let sourcePath = Stubs.sourceForDryRun + Path("Base.swift")
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [sourcePath])),
                usingTemplates: Paths(include: [templatePath]),
                output: Output("."),
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result(byOutputType: .init(id: "\(sourcePath):109", subType: .range)).value, """
        // MARK: - Eq AutoEquatable
        extension Eq: Equatable {}
        internal func == (lhs: Eq, rhs: Eq) -> Bool {
        guard lhs.s == rhs.s else { return false }
        guard lhs.o == rhs.o else { return false }
        guard lhs.u == rhs.u else { return false }
        guard lhs.r == rhs.r else { return false }
        guard lhs.c == rhs.c else { return false }
        guard lhs.e == rhs.e else { return false }
            return true
        }

        """)
        XCTAssertEqual(outputInterceptor.result(byOutputType: .init(id: "\(sourcePath):387", subType: .range)).value, """
        // MARK: - Eq2 AutoEquatable
        extension Eq2: Equatable {}
        internal func == (lhs: Eq2, rhs: Eq2) -> Bool {
        guard lhs.r == rhs.r else { return false }
        guard lhs.y == rhs.y else { return false }
        guard lhs.d == rhs.d else { return false }
        guard lhs.r2 == rhs.r2 else { return false }
        guard lhs.y2 == rhs.y2 else { return false }
        guard lhs.r3 == rhs.r3 else { return false }
        guard lhs.u == rhs.u else { return false }
        guard lhs.n == rhs.n else { return false }
            return true
        }

        """)
        let templatePathResult = outputInterceptor
            .result(byOutputType: .init(id: "\(templatePath)", subType: .template)).value
        XCTAssertEqual(templatePathResult, """
        // Generated using Sourcery

        // swiftlint:disable file_length
        fileprivate func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
            switch (lhs, rhs) {
            case let (lValue?, rValue?):
                return compare(lValue, rValue)
            case (nil, nil):
                return true
            default:
                return false
            }
        }

        fileprivate func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
            guard lhs.count == rhs.count else { return false }
            for (idx, lhsItem) in lhs.enumerated() {
                guard compare(lhsItem, rhs[idx]) else { return false }
            }

            return true
        }


        // MARK: - AutoEquatable for classes, protocols, structs



        // sourcery:inline:Eq3.AutoEquatable
        // MARK: - Eq3 AutoEquatable
        extension Eq3: Equatable {}
        internal func == (lhs: Eq3, rhs: Eq3) -> Bool {
        guard lhs.counter == rhs.counter else { return false }
        guard lhs.foo == rhs.foo else { return false }
        guard lhs.bar == rhs.bar else { return false }
            return true
        }

        // sourcery:end

        // MARK: - AutoEquatable for Enums


        """)
        XCTAssertEqual(outputInterceptor.result(byOutputType: .init(id: "Generated/EqEnum+TemplateName.generated.swift", subType: .path)).value, """
        // Generated using Sourcery

        // MARK: - EqEnum AutoEquatable
        extension EqEnum: Equatable {}
        internal func == (lhs: EqEnum, rhs: EqEnum) -> Bool {
            switch (lhs, rhs) {
            case let (.some(lhs), .some(rhs)):
                return lhs == rhs
            case let (.other(lhs), .other(rhs)):
                return lhs == rhs
            default: return false
            }
        }

        """)
    }
}

class DryOutputSwiftTemplateTests: XCTestCase {
    let outputDir = Stubs.cleanTemporarySourceryDir()
    lazy var output: Output = { Output(outputDir) }()

    let templatePath = Stubs.swiftTemplates + Path("Equality.swifttemplate")
    let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

    func test_hasNoStdoutJsonOutputIfIsDryRunEqualFalse() {
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: false
            )
        )
        XCTAssertNil(outputInterceptor.result)
    }

    func test_generatesCorrectOutputIfIsDryRunEqualTrue() {
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_handlesIncludes() {
        let templatePath = Stubs.swiftTemplates + Path("Includes.swifttemplate")
        let expectedResult = try? (Stubs.resultDirectory + Path("Basic+Other.swift")).read(.utf8)
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_handlesFileIncludes() {
        let templatePath = Stubs.swiftTemplates + Path("IncludeFile.swifttemplate")
        let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_handlesIncludesFromIncludedFilesRelatively() {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderIncludes.swifttemplate")
        let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_handlesFileIncludesFromIncludedFilesRelatively() {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderFileIncludes.swifttemplate")
        let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_handlesFreeFunctions() {
        let templatePath = Stubs.swiftTemplates + Path("Function.swifttemplate")
        let expectedResult = try? (Stubs.resultDirectory + Path("Function.swift")).read(.utf8)
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: [templatePath]),
                output: output,
                isDryRun: true
            )
        )
        XCTAssertEqual(outputInterceptor.result, expectedResult)
    }

    func test_returnAllOutputsValues() {
        let templatePaths = [
            "Includes.swifttemplate",
            "IncludeFile.swifttemplate",
            "SubfolderIncludes.swifttemplate",
            "SubfolderFileIncludes.swifttemplate",
            "Function.swifttemplate"
        ].map { Stubs.swiftTemplates + Path($0) }
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        let expectedResults = [
            "Basic+Other.swift",
            "Basic.swift",
            "Basic.swift",
            "Basic.swift",
            "Function.swift"
        ].compactMap { try? (Stubs.resultDirectory + Path($0)).read(.utf8) }

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: templatePaths),
                output: output,
                isDryRun: true
            )
        )

        XCTAssertEqual(outputInterceptor.outputModel?.outputs.count, expectedResults.count)
        XCTAssertEqual(outputInterceptor.outputModel?.outputs.map { $0.value }.sorted(), expectedResults.sorted())
    }

    func test_hasSameTemplatesInOutputsAsInInputs() {
        let templatePaths = [
            "Includes.swifttemplate",
            "IncludeFile.swifttemplate",
            "SubfolderIncludes.swifttemplate",
            "SubfolderFileIncludes.swifttemplate",
            "Function.swifttemplate"
        ].map { Stubs.swiftTemplates + Path($0) }
        let sourcery = Sourcery(cacheDisabled: true)
        let outputInterceptor = OutputInterceptor()
        sourcery.dryOutput = outputInterceptor.handleOutput(_:)

        XCTAssertNoThrow(
            try sourcery.processFiles(
                .sources(Paths(include: [Stubs.sourceDirectory])),
                usingTemplates: Paths(include: templatePaths),
                output: output,
                isDryRun: true
            )
        )

        XCTAssertEqual(
            outputInterceptor.outputModel?.outputs.compactMap { $0.type.id }.map { Path($0) }.sorted(),
            templatePaths.sorted()
        )
    }
}

private class OutputInterceptor {
    let jsonDecoder = JSONDecoder()
    var outputModel: DryOutputSuccess?
    var result: String? { outputModel?.outputs.first?.value }

    func result(byOutputType outputType: DryOutputType) -> DryOutputValue! {
        outputModel?.outputs
            .first(where: { $0.type.id == outputType.id && $0.type.subType.rawValue == outputType.subType.rawValue })
    }

    func handleOutput(_ value: String) {
        outputModel = value
            .data(using: .utf8)
            .flatMap { try? jsonDecoder.decode(DryOutputSuccess.self, from: $0) }
    }
}
