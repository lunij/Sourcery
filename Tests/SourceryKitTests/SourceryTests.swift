import Foundation
import PathKit
import XcodeProj
import XCTest
@testable import SourceryKit
@testable import SourceryRuntime

class SourceryTests: XCTestCase {
    var output: Output!

    override func setUpWithError() throws {
        try super.setUpWithError()
        output = try .init(.createTestDirectory(suffixed: "SourceryTests"))
    }

    private func createExistingFiles() -> (SourceFile, Path) {
        let sourceFile = SourceFile(path: output.path + Path("Source.swift"))
        let templatePath = Path.otherStencilPath

        "class Foo {}".update(in: sourceFile.path)

        _ = try? Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        return (sourceFile, templatePath)
    }

    func test_processFiles_whenExistingFiles_andNoChanges() {
        let (sourceFile, templatePath) = createExistingFiles()
        let generatedFilePath = output.path.appending(Path.otherStencilPath.generatedFileName)
        let generatedFileModificationDate = generatedFilePath.url.fileModificationDate()
        var newGeneratedFileModificationDate: Date?
        let expectation = expectation(description: #function)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [output] in
            _ = try? Sourcery().processConfiguration(.stub(
                sources: [sourceFile],
                templates: [templatePath],
                output: output!
            ))
            newGeneratedFileModificationDate = generatedFilePath.url.fileModificationDate()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(newGeneratedFileModificationDate, generatedFileModificationDate)
    }

    func test_processFiles_whenExistingFiles_andChanges() {
        let (sourceFile, templatePath) = createExistingFiles()
        let anotherSourceFile = SourceFile(path: output.path + Path("AnotherSource.swift"))

        "class Bar {}".update(in: anotherSourceFile.path)

        let generatedFilePath = output.path.appending(Path.otherStencilPath.generatedFileName)
        let generatedFileModificationDate = generatedFilePath.url.fileModificationDate()
        var newGeneratedFileModificationDate: Date?
        let expectation = expectation(description: #function)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [output] in
            _ = try? Sourcery().processConfiguration(.stub(
                sources: [sourceFile, anotherSourceFile],
                templates: [templatePath],
                output: output!
            ))
            newGeneratedFileModificationDate = generatedFilePath.url.fileModificationDate()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertNotEqual(newGeneratedFileModificationDate, generatedFileModificationDate)
    }

    private func createExistingFilesWithInlineTemplate() throws -> (SourceFile, Path) {
        let sourceFile = SourceFile(path: output.path + Path("Source.swift"))
        let templatePath = output.path + Path("FakeTemplate.stencil")

        """
        class Foo {
        // sourcery:inline:Foo.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        return (sourceFile, templatePath)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itReplacesPlaceholder() throws {
        let (sourceFile, _) = try createExistingFilesWithInlineTemplate()

        let expectedResult = """
        class Foo {
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itRemovesCode() throws {
        let (_, templatePath) = try createExistingFilesWithInlineTemplate()

        let expectedResult = """
        // Generated using Sourcery

        // Line One
        """

        let generatedPath = output.path.appending(templatePath.generatedFileName)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itDoesNotRemoveCode() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
        // sourcery:inline:Bar.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }
        """.update(in: sourceFile.path)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        // Generated using Sourcery

        // Line One
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """

        let generatedPath = output.path.appending(templatePath.generatedFileName)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itDoesNotCreateEmptyFile() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let generatedPath = output.path.appending(templatePath.generatedFileName)

        XCTAssertThrowsError(try generatedPath.read(.utf8))
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itInlinesMultipleCodeBlocks() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
        // sourcery:inline:Foo.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }

        class Bar {
        // sourcery:inline:Bar.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:Bar.Inlined
        var property = bar
        // Line Three
        // sourcery:end
        // Line One
        // sourcery:inline:Foo.Inlined
        var property = foo
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:Foo.Inlined
        var property = foo
        // Line Three
        // sourcery:end
        }

        class Bar {
        // sourcery:inline:Bar.Inlined
        var property = bar
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itIndentsCodeBlocks() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            // sourcery:inline:Foo.Inlined

            // This will be replaced
            Last line
            // sourcery:end

            class Bar {
                // sourcery:inline:Bar.Inlined

                // This will be replaced
                Last line
                // sourcery:end
            }
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:Bar.Inlined
        var property = bar

        // Line Three
        // sourcery:end
        // Line One
        // sourcery:inline:Foo.Inlined
        var property = foo
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
            // sourcery:inline:Foo.Inlined
            var property = foo
            // Line Three
            // sourcery:end

            class Bar {
                // sourcery:inline:Bar.Inlined
                var property = bar

                // Line Three
                // sourcery:end
            }
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheEndOfTypeBody() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}".update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheEndOfTypeBodyMaintainingIndentation() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            struct Inner {
            }
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inner.Inlined
            var property = 3
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output,
            baseIndentation: 4
        ))

        let expectedResult = """
        class Foo {
            struct Inner {

                // sourcery:inline:auto:Foo.Inner.Inlined
                    var property = 3
                // Line Three
                // sourcery:end
            }
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAfterTheEndOfTypeBody() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}\nstruct Boo {}".update(in: sourceFile.path)

        """
        // sourcery:inline:after-auto:Foo.Inlined
        var property = 2
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {}
        // sourcery:inline:after-auto:Foo.Inlined
        var property = 2
        // sourcery:end
        struct Boo {}
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheBeginningOfTypeBody() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            var property = 1 }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {

            // sourcery:inline:auto:Foo.Inlined
            var property = 2
            // Line Three
            // sourcery:end
            var property = 1 }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itSupportsUTF16() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class A {
            let 👩‍🚀: String
        }
        """.update(in: sourceFile.path)

        """
        {% for type in types.all %}
        // sourcery:inline:auto:{{ type.name }}.init
        init({% for variable in type.storedVariables %}{{variable.name}}: {{variable.typeName}}{% ifnot forloop.last %}, {% endif %}{% endfor %}) {
        {% for variable in type.storedVariables %}
            self.{{variable.name}} = {{variable.name}}
        {% endfor %}
        }
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class A {
            let 👩‍🚀: String

        // sourcery:inline:auto:A.init
        init(👩‍🚀: String) {
            self.👩‍🚀 = 👩‍🚀
        }
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itSupportsUTF16WithSourceryComments() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class A {
            let 👩‍🚀: String

            // sourcery:inline:auto:A.init
            init(👩‍🚀: String) {
                self.👩‍🚀 = 👩‍🚀
            }
            // sourcery:end
        }

        class B {
            let 👩‍🚀: String
        }
        """.update(in: sourceFile.path)

        """
        {% for type in types.all %}
        // sourcery:inline:auto:{{ type.name }}.init
        init({% for variable in type.storedVariables %}{{variable.name}}: {{variable.typeName}}{% ifnot forloop.last %}, {% endif %}{% endfor %}) {
        {% for variable in type.storedVariables %}
            self.{{variable.name}} = {{variable.name}}
        {% endfor %}
        }
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class A {
            let 👩‍🚀: String

            // sourcery:inline:auto:A.init
            init(👩‍🚀: String) {
                self.👩‍🚀 = 👩‍🚀
            }
            // sourcery:end
        }

        class B {
            let 👩‍🚀: String

        // sourcery:inline:auto:B.init
        init(👩‍🚀: String) {
            self.👩‍🚀 = 👩‍🚀
        }
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInMultipleTypes() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        class Bar {}
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Bar.Inlined
        var property = bar
        // Line Three
        // sourcery:end

        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = foo
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.Inlined
        var property = foo
        // Line Three
        // sourcery:end
        }

        class Bar {
        // sourcery:inline:auto:Bar.Inlined
        var property = bar
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsSameCodeInMultipleTypes() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
        // sourcery:inline:auto:Foo.fake
        // sourcery:end
        }

        class Bar {}
        """.update(in: sourceFile.path)

        """
        // Line One
        {% for type in types.all %}
        // sourcery:inline:auto:{{ type.name }}.fake
        var property = bar
        // Line Three
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.fake
        var property = bar
        // Line Three
        // sourcery:end
        }

        class Bar {
        // sourcery:inline:auto:Bar.fake
        var property = bar
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInNestedType() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            class Bar {}
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
            class Bar {
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        }
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInNestedTypeWithExtension() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        extension Foo {
            class Bar {}
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {}

        extension Foo {
            class Bar {
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        }
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInBothTypeAndItsNestedType() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        extension Foo {
            class Bar {}
        }
        """.update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.AutoInlined
        var property = foo
        // Line Three
        // sourcery:end
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.AutoInlined
        var property = foo
        // Line Three
        // sourcery:end
        }

        extension Foo {
            class Bar {
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        }
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inlineAuto() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}".update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.fake
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        let secondTemplatePath = output.path + Path("OtherFakeTemplate.stencil")

        """
        // sourcery:inline:auto:Foo.otherFake
        // Line Four
        // sourcery:end
        """.update(in: secondTemplatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath, secondTemplatePath],
            output: output,
            baseIndentation: 0
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.fake
        var property = 2
        // Line Three
        // sourcery:end

        // sourcery:inline:auto:Foo.otherFake
        // Line Four
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [secondTemplatePath, templatePath],
            output: output
        ))

        let newResult = try sourceFile.path.read(.utf8)
        XCTAssertEqual(newResult, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inline() throws {
        let templatePathA = output.path + Path("InlineTemplateA.stencil")
        let templatePathB = output.path + Path("InlineTemplateB.stencil")
        let sourceFile = SourceFile(path: output.path + Path("ClassWithMultipleInlineAnnotations.swift"))

        """
        class ClassWithMultipleInlineAnnotations {
        // sourcery:inline:ClassWithMultipleInlineAnnotations.A
        var a0: Int
        // sourcery:end

        // sourcery:inline:ClassWithMultipleInlineAnnotations.B
        var b0: String
        // sourcery:end
        }
        """.update(in: sourceFile.path)

        """
        {% for type in types.all %}
        // sourcery:inline:{{ type.name }}.A
        var a0: Int
        var a1: Int
        var a2: Int
        // sourcery:end
        {% endfor %}
        """.update(in: templatePathA)

        """
        {% for type in types.all %}
        // sourcery:inline:{{ type.name }}.B
        var b0: Int
        var b1: Int
        var b2: Int
        // sourcery:end
        {% endfor %}
        """.update(in: templatePathB)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePathA, templatePathB],
            output: output
        ))

        let expectedResult = """
        class ClassWithMultipleInlineAnnotations {
        // sourcery:inline:ClassWithMultipleInlineAnnotations.A
        var a0: Int
        var a1: Int
        var a2: Int
        // sourcery:end

        // sourcery:inline:ClassWithMultipleInlineAnnotations.B
        var b0: Int
        var b1: Int
        var b2: Int
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inlineAndInlineAuto() throws {
        let templatePathA = output.path + Path("InlineTemplateA.stencil")
        let templatePathB = output.path + Path("InlineTemplateB.stencil")
        let sourceFile = SourceFile(path: output.path + Path("ClassWithMultipleInlineAnnotations.swift"))

        // inline:auto annotations are inserted at the beginning of the last line of a declaration,
        // OR at the beginning of the last line of the containing file,
        // if proposed location out of bounds, which should not be.

        // To differentiate such cases the last line of a declaration
        // shall not be the last line of the file.

        """
        class ClassWithMultipleInlineAnnotations {
        // sourcery:inline:ClassWithMultipleInlineAnnotations.A
        var a0: Int
        // sourcery:end
        }
        // the last line of the file
        """.update(in: sourceFile.path)

        """
        {% for type in types.all %}
        // sourcery:inline:{{ type.name }}.A
        var a0: Int
        var a1: Int
        var a2: Int
        // sourcery:end
        {% endfor %}
        """.update(in: templatePathA)

        """
        {% for type in types.all %}
        // sourcery:inline:auto:{{ type.name }}.B
        var b0: Int
        var b1: Int
        var b2: Int
        // sourcery:end
        {% endfor %}
        """.update(in: templatePathB)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePathA, templatePathB],
            output: output
        ))

        let expectedResult = """
        class ClassWithMultipleInlineAnnotations {
        // sourcery:inline:ClassWithMultipleInlineAnnotations.A
        var a0: Int
        var a1: Int
        var a2: Int
        // sourcery:end

        // sourcery:inline:auto:ClassWithMultipleInlineAnnotations.B
        var b0: Int
        var b1: Int
        var b2: Int
        // sourcery:end
        }
        // the last line of the file
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_andCached_itInsertsCodeIfItWasDeleted() throws {
        let (sourceFile, templatePath) = try createExistingFilesWithInlineTemplate()

        removeCache(for: [sourceFile.path])

        "class Foo {}".update(in: sourceFile.path)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: Output(output.path),
            cacheDisabled: false
        ))

        "class Foo {}".update(in: sourceFile.path)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: Output(output.path),
            cacheDisabled: false
        ))

        let expectedResult = """
        class Foo {
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        }
        """

        let result = try sourceFile.path.read(.utf8)
        XCTAssertEqual(result, expectedResult)

        removeCache(for: [sourceFile.path])
    }

    private func createGivenFiles3() throws -> (SourceFile, Path) {
        let sourceFile = SourceFile(path: output.path + Path("Source.swift"))
        let templatePath = output.path + Path("FakeTemplate.stencil")

        "class Foo { }".update(in: sourceFile.path)

        """
        // Line One
        {% for type in types.all %}
        // sourcery:file:Generated/{{ type.name }}
        extension {{ type.name }} {
        var property = 2
        // Line Three
        }
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        return (sourceFile, templatePath)
    }

    func test_processFiles_andPerFileGeneration_itReplacesPlaceholderWithCode() throws {
        _ = try createGivenFiles3()

        let expectedResult = """
        // Generated using Sourcery

        extension Foo {
        var property = 2
        // Line Three
        }

        """

        let generatedPath = output.path + Path("Generated/Foo.generated.swift")

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_andPerFileGeneration_itRemovesCodeFromWithinGeneratedTemplate() throws {
        let (_, templatePath) = try createGivenFiles3()

        let expectedResult = """
        // Generated using Sourcery

        // Line One

        """

        let generatedPath = output.path.appending(templatePath.generatedFileName)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_andPerFileGeneration_itDoesNotCreateFileWithEmptyContent() throws {
        let (sourceFile, templatePath) = try createGivenFiles3()

        """
        {% for type in types.all %}
        // sourcery:file:Generated/{{ type.name }}
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let generatedPath = output.path + Path("Generated/Foo.generated.swift")

        let result = try? generatedPath.read(.utf8)
        XCTAssertNil(result)
    }

    func test_processFiles_andPerFileGeneration_itAppendsContentOfSeveralAnnotationsIntoOneFile() throws {
        let (sourceFile, templatePath) = try createGivenFiles3()

        """
        // Line One
        // sourcery:file:Generated/Foo
        extension Foo {
        var property1 = 1
        }
        // sourcery:end
        // sourcery:file:Generated/Foo
        extension Foo {
        var property2 = 2
        }
        // sourcery:end
        """.update(in: templatePath)

        let expectedResult = """
        // Generated using Sourcery

        extension Foo {
        var property1 = 1
        }

        extension Foo {
        var property2 = 2
        }

        """

        try Sourcery().processConfiguration(.stub(
            sources: [sourceFile],
            templates: [templatePath],
            output: output
        ))

        let generatedPath = output.path + Path("Generated/Foo.generated.swift")

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_andRestrictedFile_itIgnoresSourceryGeneratedFiles() throws {
        let targetPath = output.path.appending(Path.basicStencilPath.generatedFileName)

        _ = try? targetPath.delete()

        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.resultDirectory + Path("Basic.swift"))],
            templates: [.basicStencilPath],
            output: output, baseIndentation: 0
        ))

        XCTAssertFalse(targetPath.exists)
    }

    func test_failsProcessingConfig_whenSourceFileMissing() {
        XCTAssertThrowsError(try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: "Missing.swift")],
            templates: [.basicStencilPath],
            output: Output(output.path)
        ))) { error in
            let error = error as? ConfigurationValidationError
            XCTAssertEqual(error, .fileNotReadable("Missing.swift"))
        }
    }

    func test_processFiles_whenNoWatcher_itCreatesExpectedOutputFile() throws {
        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [.basicStencilPath],
            output: output
        ))

        let result = try output.path.appending(Path.basicStencilPath.generatedFileName).read(.utf8)
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8).withoutWhitespaces
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenWatcher_itRegeneratesOnTemplateChange() throws {
        let templatePath = output.path + Path("FakeTemplate.stencil")

        "Found {{ types.enums.count }} Enums".update(in: templatePath)

        let eventStreams = try Sourcery(watcherEnabled: true).processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            output: output
        ))

        "Found {{ types.all.count }} Types".update(in: templatePath)

        XCTAssertEqual(eventStreams.count, 2)

        assertContinuously {
            try output.path.appending(templatePath.generatedFileName).read(.utf8)
        } until: {
            $0.contains("\(String.generatedHeader)Found 3 Types")
        }
    }

    func test_processFiles_whenTemplateFolder_itCreatesGeneratedFileForEachTemplate() throws {
        try Sourcery().processConfiguration(.stub(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [Stubs.templateDirectory],
            output: output
        ))

        XCTAssertTrue(output.path.appending("Basic.generated.swift").exists)
        XCTAssertTrue(output.path.appending("GenerationWays.generated.swift").exists)
        XCTAssertTrue(output.path.appending("Include.generated.swift").exists)
        XCTAssertTrue(output.path.appending("Other.generated.swift").exists)
        XCTAssertTrue(output.path.appending("Partial.generated.swift").exists)
    }

    private func createProjectScenario(templatePath: Path) throws -> ProjectScenario {
        let projectPath = Stubs.sourceDirectory + "TestProject"
        let projectFilePath = Stubs.sourceDirectory + "TestProject/TestProject.xcodeproj"
        let project = try XcodeProj(path: projectFilePath)
        return .init(
            sources: [SourceFile(path: Stubs.sourceDirectory)],
            templates: [templatePath],
            originalProject: project,
            projectPath: projectPath,
            projectFilePath: projectFilePath
        )
    }

    func test_processFiles_whenProject_itLinksGeneratedFiles() throws {
        let scenario = try createProjectScenario(templatePath: .otherStencilPath)

        try Sourcery().processConfiguration(.stub(
            sources: scenario.sources,
            templates: scenario.templates,
            output: scenario.createOutput(at: output.path)
        ))

        XCTAssertTrue(scenario.sourceFilesPaths.contains(output.path + "Other.generated.swift"))
        XCTAssertNoThrow(try scenario.originalProject.writePBXProj(path: scenario.projectFilePath, outputSettings: .init()))
    }

    func test_processFiles_whenProject_itLinksGeneratedFilesWhenUsingPerFileGeneration() throws {
        let templatePath = output.path + "PerFileGeneration.stencil"
        let scenario = try createProjectScenario(templatePath: templatePath)

        """
        // Line One
        {% for type in types.all %}
        // sourcery:file:Generated/{{ type.name }}.generated.swift
        extension {{ type.name }} {
        var property = 2
        // Line Three
        }
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        try Sourcery().processConfiguration(.stub(
            sources: scenario.sources,
            templates: scenario.templates,
            output: scenario.createOutput(at: output.path)
        ))

        XCTAssertTrue(scenario.sourceFilesPaths.contains(output.path + "PerFileGeneration.generated.swift"))
        XCTAssertTrue(scenario.sourceFilesPaths.contains(output.path + "Generated/Foo.generated.swift"))
        XCTAssertNoThrow(try scenario.originalProject.writePBXProj(path: scenario.projectFilePath, outputSettings: .init()))
    }
}

private extension Path {
    static let basicStencilPath = Stubs.templateDirectory + Path("Basic.stencil")
    static let otherStencilPath = Stubs.templateDirectory + Path("Other.stencil")
}

private extension String {
    func update(in path: Path, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try path.write(self)
        } catch {
            XCTFail(String(describing: error), file: file, line: line)
        }
    }
}

private extension URL {
    func fileModificationDate(file: StaticString = #filePath, line: UInt = #line) -> Date {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return try XCTUnwrap(attributes[FileAttributeKey.modificationDate] as? Date)
        } catch {
            XCTFail(String(describing: error), file: file, line: line)
            return Date()
        }
    }
}

private struct ProjectScenario {
    let sources: [SourceFile]
    let templates: [Path]
    let originalProject: XcodeProj
    let projectPath: Path
    let projectFilePath: Path

    var sourceFilesPaths: [Path] {
        guard
            let project = try? XcodeProj(path: projectFilePath),
            let target = project.target(named: "TestProject")
        else {
            return []
        }
        return project.sourceFilesPaths(target: target, sourceRoot: projectPath)
    }

    func createOutput(at path: Path) throws -> Output {
        let projectPath = projectPath + "TestProject.xcodeproj"
        return try Output(path, link: .init(
            project: XcodeProj(path: projectPath),
            projectPath: projectPath,
            targets: ["TestProject"],
            group: nil
        ))
    }
}

private func assertContinuously(
    repeats: Int = 3,
    delay: TimeInterval = 1,
    execute: () throws -> String,
    until assert: (String) -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        guard repeats > 0 else {
            return XCTFail("No repeats left", file: file, line: line)
        }
        let result = try execute()
        if assert(result) { return }
        Thread.sleep(forTimeInterval: delay)
        assertContinuously(repeats: repeats - 1, execute: execute, until: assert, file: file, line: line)
    } catch {
        XCTFail(String(describing: error), file: file, line: line)
    }
}

private func removeCache(for sources: [Path], cacheBasePath: Path? = nil) {
    sources.forEach { path in
        let cacheDir = Path.cachesDir(sourcePath: path, basePath: cacheBasePath, createIfMissing: false)
        _ = try? cacheDir.delete()
    }
}
