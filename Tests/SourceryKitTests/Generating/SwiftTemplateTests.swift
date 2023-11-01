import Foundation
import PathKit
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class SwiftTemplateTests: XCTestCase {
    var output: Path!

    let templatePath = Stubs.swiftTemplates + Path("Equality.swifttemplate")
    let expectedResult = try? (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

    override func setUpWithError() throws {
        try super.setUpWithError()
        output = try .init(.createTestDirectory(suffixed: "SwiftTemplateTests"))
    }

    func test_createsPersistableData() throws {
        func templateContextData(_ code: String) throws -> TemplateContext {
            let parserResult = try SwiftSyntaxParser(contents: code).parse()
            let data = try NSKeyedArchiver.archivedData(withRootObject: parserResult, requiringSecureCoding: false)

            let result = Composer.uniqueTypesAndFunctions(parserResult)
            let unarchivedParserResult = try NSKeyedUnarchiver.unarchivedRootObject(ofClass: FileParserResult.self, from: data)
            return TemplateContext(parserResult: unarchivedParserResult, types: .init(types: result.types, typealiases: result.typealiases), functions: result.functions, arguments: [:])
        }

        let context = try templateContextData("""
        public struct Periodization {
            public typealias Action = Identified<UUID, ActionType>
            public struct ActionType {
                public static let prototypes: [Action] = []
            }
        }
        """)

        let data = try NSKeyedArchiver.archivedData(withRootObject: context, requiringSecureCoding: false)
        let unarchived = try NSKeyedUnarchiver.unarchivedRootObject(ofClass: TemplateContext.self, from: data)

        XCTAssertEqual(context.types, unarchived?.types)
    }

    func test_generatesCorrectOutput() throws {
        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_throwsAnErrorShowingTheInvolvedLineForUnmatchedDelimiterInTheTemplate() {
        let templatePath = Stubs.swiftTemplates + Path("InvalidTag.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "Missing closing tag '%>' in \(templatePath):2")
        }
    }

    func test_handlesIncludes() throws {
        let templatePath = Stubs.swiftTemplates + Path("Includes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic+Other.swift")).read(.utf8)

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFileIncludes() throws {
        let templatePath = Stubs.swiftTemplates + Path("IncludeFile.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesIncludesFromIncludedFilesRelatively() throws {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderIncludes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFileIncludesFromIncludedFilesRelatively() throws {
        let templatePath = Stubs.swiftTemplates + Path("SubfolderFileIncludes.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8)

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_detectsIncludeCycles() {
        let templatePath = Stubs.swiftTemplates + Path("IncludeCycle.swifttemplate")
        let includeCycleTemplatePath = Stubs.swiftTemplates + Path("includeCycle/Two.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "Include cycle detected for One.swifttemplate in \(includeCycleTemplatePath):1")
        }
    }

    func test_detectsIncludeCycles_whenReferencingRootTemplate() {
        let templatePath = Stubs.swiftTemplates + Path("SelfIncludeCycle.swifttemplate")
        XCTAssertThrowsError(try SwiftTemplate(path: templatePath)) { error in
            XCTAssertEqual("\(error)", "Include cycle detected for SelfIncludeCycle.swifttemplate in \(templatePath):1")
        }
    }

    func test_rethrowsTemplateParsingErrors() {
        let templatePath = Stubs.swiftTemplates + Path("Invalid.swifttemplate")
        XCTAssertThrowsError(
            try SwiftTemplate(path: templatePath).render(.init(
                parserResult: .init(path: nil, module: nil, types: [], functions: []),
                types: Types(types: []),
                functions: [],
                arguments: [:]
            ))
        ) { error in
            let path = try! Path.createTestDirectory(suffixed: "build").parent() + "Sourcery-SwiftTemplate/Invalid/Sources/SwiftTemplate/main.swift"
            XCTAssertTrue("\(error)".contains("\(path):10:10: error: missing argument for parameter #1 in call\nprint(\"\\()\", terminator: \"\")\n         ^\n"))
        }
    }

    func test_rethrowsTemplateRuntimeErrors() {
        let templatePath = Stubs.swiftTemplates + Path("Runtime.swifttemplate")
        XCTAssertThrowsError(
            try SwiftTemplate(path: templatePath).render(TemplateContext(
                parserResult: .init(path: nil, module: nil, types: [], functions: []),
                types: Types(types: []),
                functions: [],
                arguments: [:]
            ))
        ) { error in
            XCTAssertEqual("\(error)", "\(templatePath): Unknown type Some, should be used with `based`")
        }
    }

    func test_rethrowsErrorsThrownInTemplate() {
        let templatePath = Stubs.swiftTemplates + Path("Throws.swifttemplate")
        XCTAssertThrowsError(
            try SwiftTemplate(path: templatePath).render(TemplateContext(
                parserResult: .init(path: nil, module: nil, types: [], functions: []),
                types: Types(types: []),
                functions: [],
                arguments: [:]
            ))
        ) { error in
            XCTAssertTrue("\(error)".contains("\(templatePath): SwiftTemplate/main.swift:10: Fatal error: Template not implemented"))
        }
    }

    func test_cache_whenMissingBuildDir() throws {
        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output,
            cacheDisabled: false
        ))
        XCTAssertEqual(try output.appending(templatePath.generatedFileName).read(.utf8), expectedResult)

        guard let buildDir = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SwiftTemplate").map({ Path($0.path) }) else {
            XCTFail("Could not create buildDir path")
            return
        }
        if buildDir.exists {
            try buildDir.delete()
        }

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output,
            cacheDisabled: false
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_handlesFreeFunctions() throws {
        let templatePath = Stubs.swiftTemplates + Path("Function.swifttemplate")
        let expectedResult = try (Stubs.resultDirectory + Path("Function.swift")).read(.utf8)

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        let result = try output.appending(templatePath.generatedFileName).read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_shouldChangeCacheKeyBasedOnIncludeFileModifications() throws {
        let templatePath = output + "Template.swifttemplate"
        try templatePath.write(#"<%- include("Utils.swift") -%>"#)

        let utilsPath = output + "Utils.swift"
        try utilsPath.write(#"let foo = "bar""#)

        let template = try SwiftTemplate(path: templatePath, cachePath: nil)
        let originalKey = template.cacheKey
        let keyBeforeModification = template.cacheKey

        try utilsPath.write(#"let foo = "baz""#)

        let keyAfterModification = template.cacheKey
        XCTAssertEqual(originalKey, keyBeforeModification)
        XCTAssertNotEqual(originalKey, keyAfterModification)
    }
}

class FolderSynchronizerTests: XCTestCase {
    var output: Path!
    let files: [FolderSynchronizer.File] = [.init(name: "file.swift", content: "Swift code")]

    override func setUpWithError() throws {
        try super.setUpWithError()
        output = try Path.createTestDirectory(suffixed: "FolderSynchronizerTests")
    }

    func test_addsItsFilesToAnEmptyFolder() throws {
        try FolderSynchronizer().sync(files: files, to: output)

        let newFile = output + Path("file.swift")
        XCTAssertEqual(newFile.exists, true)
        XCTAssertEqual(try newFile.read(), "Swift code")
    }

    func test_createsTheTargetFolderIfItDoesNotExist() throws {
        let synchronizedFolder = output + Path("Folder")

        try FolderSynchronizer().sync(files: files, to: synchronizedFolder)

        XCTAssertEqual(synchronizedFolder.exists, true)
        XCTAssertEqual(synchronizedFolder.isDirectory, true)
    }

    func test_deletesFilesNotPresentInTheSynchronizedFiles() throws {
        let existingFile = output + Path("Existing.swift")
        try existingFile.write("Discarded")

        try FolderSynchronizer().sync(files: files, to: output)

        XCTAssertEqual(existingFile.exists, false)
        let newFile = output + Path("file.swift")
        XCTAssertEqual(newFile.exists, true)
        XCTAssertEqual(try newFile.read(), "Swift code")
    }

    func test_replacesTheContentOfAFileIfAFileWithTheSameNameAlreadyExists() throws {
        let existingFile = output + Path("file.swift")
        try existingFile.write("Discarded")
        try FolderSynchronizer().sync(files: files, to: output)

        XCTAssertEqual(try existingFile.read(), "Swift code")
    }
}
