import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class SwiftTemplateTests: XCTestCase {
    let outputDir = Stubs.cleanTemporarySourceryDir()
    lazy var output: Output = { Output(outputDir) }()

    let templatePath = Stubs.swiftTemplates + Path("Equality.swifttemplate")
    let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

    func test_createsPersistableData() throws {
        func templateContextData(_ code: String) throws -> TemplateContext? {
            let parserResult = try makeParser(for: code).parse()
            let data = NSKeyedArchiver.archivedData(withRootObject: parserResult)

            let result = Composer.uniqueTypesAndFunctions(parserResult)
            return TemplateContext(parserResult: try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? FileParserResult, types: .init(types: result.types, typealiases: result.typealiases), functions: result.functions, arguments: [:])
        }

        let maybeContext = try templateContextData("""
        public struct Periodization {
            public typealias Action = Identified<UUID, ActionType>
            public struct ActionType {
                public static let prototypes: [Action] = []
            }
        }
        """)

        let context = try XCTUnwrap(maybeContext)
        let data = NSKeyedArchiver.archivedData(withRootObject: context)
        let unarchived = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? TemplateContext

        XCTAssertEqual(context.types, unarchived?.types)
    }

    func test_generatesCorrectOutput() throws {
        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_throwsAnErrorShowingTheInvolvedLineForUnmatchedDelimiterInTheTemplate() {
        let templatePath = Stubs.swiftTemplates + Path("InvalidTag.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "\(templatePath):2 Error while parsing template. Unmatched <%")
        }
    }

    func test_handlesIncludes() throws {
        let templatePath = Stubs.swiftTemplates + Path("Includes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic+Other.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFileIncludes() throws {
        let templatePath = Stubs.swiftTemplates + Path("IncludeFile.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesIncludesWithoutSwifttemplateExtension() throws {
        let templatePath = Stubs.swiftTemplates + Path("IncludesNoExtension.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic+Other.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFileIncludesWithoutSwiftExtension() throws {
        let templatePath = Stubs.swiftTemplates + Path("IncludeFileNoExtension.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesIncludesFromIncludedFilesRelatively() throws {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderIncludes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFileIncludesFromIncludedFilesRelatively() throws {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderFileIncludes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_throwsAnErrorWhenAnIncludeCycleIsDetected() {
        let templatePath = Stubs.swiftTemplates + Path("IncludeCycle.swifttemplate")
        let templateCycleDetectionLocationPath = Stubs.swiftTemplates + Path("includeCycle/Two.swifttemplate")
        let templateInvolvedInCyclePath = Stubs.swiftTemplates + Path("includeCycle/One.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "\(templateCycleDetectionLocationPath):1 Error: Include cycle detected for \(templateInvolvedInCyclePath). Check your include statements so that templates do not include each other.")
        }
    }

    func test_throwsAnErrorWhenAnIncludeCycleInvolvingTheRootTemplateIsDetected() {
        let templatePath = Stubs.swiftTemplates + Path("SelfIncludeCycle.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "\(templatePath):1 Error: Include cycle detected for \(templatePath). Check your include statements so that templates do not include each other.")
        }
    }

    func test_rethrowsTemplateParsingErrors() {
        let templatePath = Stubs.swiftTemplates + Path("Invalid.swifttemplate")
        XCTAssertThrowsError(
            try Generator.generate(.init(path: nil, module: nil, types: [], functions: []), types: Types(types: []), functions: [], template: SwiftTemplate(path: templatePath, version: "version"))
        ) { error in
            let path = Path.cleanTemporaryDir(name: "build").parent() + "SwiftTemplate/version/Sources/SwiftTemplate/main.swift"
            XCTAssertTrue("\(error)".contains("\(path):10:11: error: missing argument for parameter #1 in call\nprint(\"\\( )\", terminator: \"\");\n          ^\n"))
        }
    }

    func test_rethrowsTemplateRuntimeErrors() {
        let templatePath = Stubs.swiftTemplates + Path("Runtime.swifttemplate")
        XCTAssertThrowsError(
            try Generator.generate(.init(path: nil, module: nil, types: [], functions: []), types: Types(types: []), functions: [], template: SwiftTemplate(path: templatePath))
        ) { error in
            XCTAssertEqual("\(error)", "\(templatePath): Unknown type Some, should be used with `based`")
        }
    }

    func test_rethrowsErrorsThrownInTemplate() {
        let templatePath = Stubs.swiftTemplates + Path("Throws.swifttemplate")
        XCTAssertThrowsError(
            try Generator.generate(.init(path: nil, module: nil, types: [], functions: []), types: Types(types: []), functions: [], template: SwiftTemplate(path: templatePath))
        ) { error in
            XCTAssertTrue("\(error)".contains("\(templatePath): SwiftTemplate/main.swift:10: Fatal error: Template not implemented"))
        }
    }

    func test_cache_whenMissingBuildDir() throws {
        _ = try Sourcery(cacheDisabled: false).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )
        XCTAssertEqual(try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8), expectedResult)

        guard let buildDir = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SwiftTemplate").map({ Path($0.path) }) else {
            XCTFail("Could not create buildDir path")
            return
        }
        if buildDir.exists {
            try buildDir.delete()
        }

        _ = try Sourcery(cacheDisabled: false).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFreeFunctions() throws {
        let templatePath = Stubs.swiftTemplates + Path("Function.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Function.swift")).read(.utf8)

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_shouldChangeCacheKeyBasedOnIncludeFileModifications() throws {
        let templatePath = outputDir + "Template.swifttemplate"
        try templatePath.write(#"<%- includeFile("Utils.swift") -%>"#)

        let utilsPath = outputDir + "Utils.swift"
        try utilsPath.write(#"let foo = "bar""#)

        let template = try SwiftTemplate(path: templatePath, cachePath: nil, version: "1.0.0")
        let originalKey = template.cacheKey
        let keyBeforeModification = template.cacheKey

        try utilsPath.write(#"let foo = "baz""#)

        let keyAfterModification = template.cacheKey
        XCTAssertEqual(originalKey, keyBeforeModification)
        XCTAssertNotEqual(originalKey, keyAfterModification)
    }
}

class FolderSynchronizerTests: XCTestCase {
    let outputDir = Stubs.cleanTemporarySourceryDir()
    let files: [FolderSynchronizer.File] = [.init(name: "file.swift", content: "Swift code")]

    func test_addsItsFilesToAnEmptyFolder() throws {
        try FolderSynchronizer().sync(files: files, to: outputDir)

        let newFile = outputDir + Path("file.swift")
        XCTAssertEqual(newFile.exists, true)
        XCTAssertEqual(try newFile.read(), "Swift code")
    }

    func test_createsTheTargetFolderIfItDoesNotExist() throws {
        let synchronizedFolder = outputDir + Path("Folder")

        try FolderSynchronizer().sync(files: files, to: synchronizedFolder)

        XCTAssertEqual(synchronizedFolder.exists, true)
        XCTAssertEqual(synchronizedFolder.isDirectory, true)
    }

    func test_deletesFilesNotPresentInTheSynchronizedFiles() throws {
        let existingFile = outputDir + Path("Existing.swift")
        try existingFile.write("Discarded")

        try FolderSynchronizer().sync(files: files, to: outputDir)

        XCTAssertEqual(existingFile.exists, false)
        let newFile = outputDir + Path("file.swift")
        XCTAssertEqual(newFile.exists, true)
        XCTAssertEqual(try newFile.read(), "Swift code")
    }

    func test_replacesTheContentOfAFileIfAFileWithTheSameNameAlreadyExists() throws {
        let existingFile = outputDir + Path("file.swift")
        try existingFile.write("Discarded")
        try FolderSynchronizer().sync(files: files, to: outputDir)

        XCTAssertEqual(try existingFile.read(), "Swift code")
    }
}
