import Foundation
import PathKit
import XcodeProj
import XCTest
@testable import SourceryLib
@testable import SourceryRuntime

private let version = "Major.Minor.Patch"

class SourceryTests: XCTestCase {
    var outputDir = Path("/tmp")
    var output: Output { Output(outputDir) }

    override func setUp() {
        outputDir = Stubs.cleanTemporarySourceryDir()
    }

    private func createExistingFiles() -> Path {
        let sourcePath = outputDir + Path("Source.swift")

        "class Foo {}".update(in: sourcePath)

        _ = try? Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [.otherStencilPath]),
            output: output,
            baseIndentation: 0
        )

        return sourcePath
    }

    func test_processFiles_whenExistingFiles_andNoChanges() {
        let sourcePath = createExistingFiles()
        let generatedFilePath = outputDir + Sourcery().generatedPath(for: .otherStencilPath)
        let generatedFileModificationDate = generatedFilePath.url.fileModificationDate()
        var newGeneratedFileModificationDate: Date?
        let expectation = expectation(description: #function)

        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [output] in
            _ = try? Sourcery(watcherEnabled: false, cacheDisabled: true)
                .processFiles(.sources(Paths(include: [sourcePath])), usingTemplates: Paths(include: [.otherStencilPath]), output: output, baseIndentation: 0)
            newGeneratedFileModificationDate = generatedFilePath.url.fileModificationDate()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(newGeneratedFileModificationDate, generatedFileModificationDate)
    }

    func test_processFiles_whenExistingFiles_andChanges() {
        let sourcePath = createExistingFiles()
        let anotherSourcePath = outputDir + Path("AnotherSource.swift")

        "class Bar {}".update(in: anotherSourcePath)

        let generatedFilePath = outputDir + Sourcery().generatedPath(for: .otherStencilPath)
        let generatedFileModificationDate = generatedFilePath.url.fileModificationDate()
        var newGeneratedFileModificationDate: Date?
        let expectation = expectation(description: #function)

        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [output] in
            _ = try? Sourcery(watcherEnabled: false, cacheDisabled: true)
                .processFiles(.sources(Paths(include: [sourcePath, anotherSourcePath])), usingTemplates: Paths(include: [.otherStencilPath]), output: output, baseIndentation: 0)
            newGeneratedFileModificationDate = generatedFilePath.url.fileModificationDate()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertNotEqual(newGeneratedFileModificationDate, generatedFileModificationDate)
    }

    private func createExistingFilesWithInlineTemplate() throws -> (Path, Path) {
        let sourcePath = outputDir + Path("Source.swift")
        let templatePath = outputDir + Path("FakeTemplate.stencil")

        """
        class Foo {
        // sourcery:inline:Foo.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }
        """.update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        return (sourcePath, templatePath)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itReplacesPlaceholder() throws {
        let (sourcePath, _) = try createExistingFilesWithInlineTemplate()

        let expectedResult = """
            class Foo {
            // sourcery:inline:Foo.Inlined
            var property = 2
            // Line Three
            // sourcery:end
            }
            """

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itRemovesCode() throws {
        let (_, templatePath) = try createExistingFilesWithInlineTemplate()

        let expectedResult = """
            // Generated using Sourcery Major.Minor.Patch — https://github.com/krzysztofzablocki/Sourcery
            // DO NOT EDIT

            // Line One
            """

        let generatedPath = outputDir + Sourcery().generatedPath(for: templatePath)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itDoesNotRemoveCode() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
        // sourcery:inline:Bar.Inlined

        // This will be replaced
        Last line
        // sourcery:end
        }
        """.update(in: sourcePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let expectedResult = """
            // Generated using Sourcery Major.Minor.Patch — https://github.com/krzysztofzablocki/Sourcery
            // DO NOT EDIT

            // Line One
            // sourcery:inline:Foo.Inlined
            var property = 2
            // Line Three
            // sourcery:end
            """

        let generatedPath = outputDir + Sourcery().generatedPath(for: templatePath)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itDoesNotCreateEmptyFile() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        // sourcery:inline:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true, prune: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let generatedPath = outputDir + Sourcery().generatedPath(for: templatePath)

        XCTAssertThrowsError(try generatedPath.read(.utf8))
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itInlinesMultipleCodeBlocks() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

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
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andInlineGeneration_itIndentsCodeBlocks() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

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
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheEndOfTypeBody() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}".update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let expectedResult = """
            class Foo {
            // sourcery:inline:auto:Foo.Inlined
            var property = 2
            // Line Three
            // sourcery:end
            }
            """

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheEndOfTypeBodyMaintainingIndentation() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            struct Inner {
            }
        }
        """.update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inner.Inlined
            var property = 3
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 4
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAfterTheEndOfTypeBody() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}\nstruct Boo {}".update(in: sourcePath)

        """
        // sourcery:inline:after-auto:Foo.Inlined
        var property = 2
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let expectedResult = """
            class Foo {}
            // sourcery:inline:after-auto:Foo.Inlined
            var property = 2
            // sourcery:end
            struct Boo {}
            """

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeAtTheBeginningOfTypeBody() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            var property = 1 }
        """.update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let expectedResult = """
            class Foo {

                // sourcery:inline:auto:Foo.Inlined
                var property = 2
                // Line Three
                // sourcery:end
                var property = 1 }
            """

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itSupportsUTF16() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class A {
            let 👩‍🚀: String
        }
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itSupportsUTF16WithSourceryComments() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

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
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInMultipleTypes() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        class Bar {}
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])), 
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsSameCodeInMultipleTypes() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
        // sourcery:inline:auto:Foo.fake
        // sourcery:end
        }

        class Bar {}
        """.update(in: sourcePath)

        """
        // Line One
        {% for type in types.all %}
        // sourcery:inline:auto:{{ type.name }}.fake
        var property = bar
        // Line Three
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInNestedType() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {
            class Bar {}
        }
        """.update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInNestedTypeWithExtension() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        extension Foo {
            class Bar {}
        }
        """.update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Bar.AutoInlined
        var property = bar
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeInBothTypeAndItsNestedType() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        """
        class Foo {}

        extension Foo {
            class Bar {}
        }
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inlineAuto() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        "class Foo {}".update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.fake
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        let secondTemplatePath = outputDir + Path("OtherFakeTemplate.stencil")

        """
        // sourcery:inline:auto:Foo.otherFake
        // Line Four
        // sourcery:end
        """.update(in: secondTemplatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [secondTemplatePath, templatePath]),
            output: output, 
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [secondTemplatePath, templatePath]),
            output: output,
            baseIndentation: 0
        )

        let newResult = try sourcePath.read(.utf8)
        XCTAssertEqual(newResult, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inline() throws {
        let templatePathA = outputDir + Path("InlineTemplateA.stencil")
        let templatePathB = outputDir + Path("InlineTemplateB.stencil")
        let sourcePath = outputDir + Path("ClassWithMultipleInlineAnnotations.swift")

        """
        class ClassWithMultipleInlineAnnotations {
        // sourcery:inline:ClassWithMultipleInlineAnnotations.A
        var a0: Int
        // sourcery:end

        // sourcery:inline:ClassWithMultipleInlineAnnotations.B
        var b0: String
        // sourcery:end
        }
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePathA, templatePathB]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_itInsertsCodeFromDifferentTemplates_inlineAndInlineAuto() throws {
        let templatePathA = outputDir + Path("InlineTemplateA.stencil")
        let templatePathB = outputDir + Path("InlineTemplateB.stencil")
        let sourcePath = outputDir + Path("ClassWithMultipleInlineAnnotations.swift")

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
        """.update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePathA, templatePathB]),
            output: output,
            baseIndentation: 0
        )

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

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_whenSingleTemplate_andAutoInlineGeneration_andCached_itInsertsCodeIfItWasDeleted() throws {
        let (sourcePath, templatePath) = try createExistingFilesWithInlineTemplate()

        Sourcery.removeCache(for: [sourcePath])

        "class Foo {}".update(in: sourcePath)

        """
        // Line One
        // sourcery:inline:auto:Foo.Inlined
        var property = 2
        // Line Three
        // sourcery:end
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: false).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: Output(outputDir, linkTo: nil),
            baseIndentation: 0
        )

        "class Foo {}".update(in: sourcePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: false).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: Output(outputDir, linkTo: nil),
            baseIndentation: 0
        )

        let expectedResult = """
            class Foo {
            // sourcery:inline:auto:Foo.Inlined
            var property = 2
            // Line Three
            // sourcery:end
            }
            """

        let result = try sourcePath.read(.utf8)
        XCTAssertEqual(result, expectedResult)

        Sourcery.removeCache(for: [sourcePath])
    }

    private func createGivenFiles3() throws -> (Path, Path) {
        let sourcePath = outputDir + Path("Source.swift")
        let templatePath = outputDir + Path("FakeTemplate.stencil")

        "class Foo { }".update(in: sourcePath)

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

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        return (sourcePath, templatePath)
    }

    func test_processFiles_andPerFileGeneration_itReplacesPlaceholderWithCode() throws {
        _ = try createGivenFiles3()

        let expectedResult = """
            // Generated using Sourcery Major.Minor.Patch — https://github.com/krzysztofzablocki/Sourcery
            // DO NOT EDIT
            extension Foo {
            var property = 2
            // Line Three
            }

            """

        let generatedPath = outputDir + Path("Generated/Foo.generated.swift")

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_andPerFileGeneration_itRemovesCodeFromWithinGeneratedTemplate() throws {
        let (_, templatePath) = try createGivenFiles3()

        let expectedResult = """
            // Generated using Sourcery Major.Minor.Patch — https://github.com/krzysztofzablocki/Sourcery
            // DO NOT EDIT

            // Line One

            """

        let generatedPath = outputDir + Sourcery().generatedPath(for: templatePath)

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_andPerFileGeneration_itDoesNotCreateFileWithEmptyContent() throws {
        let (sourcePath, templatePath) = try createGivenFiles3()

        """
        {% for type in types.all %}
        // sourcery:file:Generated/{{ type.name }}
        // sourcery:end
        {% endfor %}
        """.update(in: templatePath)

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true, prune: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let generatedPath = outputDir + Path("Generated/Foo.generated.swift")

        let result = try? generatedPath.read(.utf8)
        XCTAssertNil(result)
    }

    func test_processFiles_andPerFileGeneration_itAppendsContentOfSeveralAnnotationsIntoOneFile() throws {
        let (sourcePath, templatePath) = try createGivenFiles3()

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
            // Generated using Sourcery Major.Minor.Patch — https://github.com/krzysztofzablocki/Sourcery
            // DO NOT EDIT
            extension Foo {
            var property1 = 1
            }

            extension Foo {
            var property2 = 2
            }

            """

        _ = try Sourcery(watcherEnabled: false, cacheDisabled: true, prune: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        let generatedPath = outputDir + Path("Generated/Foo.generated.swift")

        let result = try generatedPath.read(.utf8)
        XCTAssertEqual(result, expectedResult)
    }

    func test_processFiles_andRestrictedFile_itIgnoresSourceryGeneratedFiles() throws {
        let targetPath = outputDir + Sourcery().generatedPath(for: .basicStencilPath)

        _ = try? targetPath.delete()

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.resultDirectory] + Path("Basic.swift"))),
            usingTemplates: Paths(include: [.basicStencilPath]),
            output: output, baseIndentation: 0
        )

        XCTAssertFalse(targetPath.exists)
    }

    func test_processFiles_andRestrictedFile_itThrowsErrorWhenFileContainsMergeConflictMarkers() {
        let sourcePath = outputDir + Path("Source.swift")

        """


        <<<<<

        """.update(in: sourcePath)

        XCTAssertThrowsError(try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [.basicStencilPath]),
            output: output,
            baseIndentation: 0
        )) {
            let error = $0 as? Sourcery.Error
            XCTAssertEqual(error, .containsMergeConflictMarkers)
        }
    }

    func test_processFiles_andRestrictedFile_itDoesNotThrowWhenSourceFileDoesNotExist() {
        let sourcePath = outputDir + Path("Missing.swift")

        XCTAssertNoThrow(try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [sourcePath])),
            usingTemplates: Paths(include: [.basicStencilPath]),
            output: Output(outputDir, linkTo: nil),
            baseIndentation: 0
        ))
    }

    func test_processFiles_ignoresExcludedSourcePaths() throws {
        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory], exclude: [Stubs.sourceDirectory + "Foo.swift"])),
            usingTemplates: Paths(include: [.basicStencilPath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: .basicStencilPath)).read(.utf8)
        let expectedResult = try (Stubs.resultDirectory + Path("BasicFooExcluded.swift")).read(.utf8).withoutWhitespaces
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenNoWatcher_itCreatesExpectedOutputFile() throws {
        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [.basicStencilPath]),
            output: output,
            baseIndentation: 0
        )

        let result = try (outputDir + Sourcery().generatedPath(for: .basicStencilPath)).read(.utf8)
        let expectedResult = try (Stubs.resultDirectory + Path("Basic.swift")).read(.utf8).withoutWhitespaces
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    func test_processFiles_whenWatcher_itRegeneratesOnTemplateChange() throws {
        var watcher: Any?
        let templatePath = outputDir + Path("FakeTemplate.stencil")

        "Found {{ types.enums.count }} Enums".update(in: templatePath)

        watcher = try Sourcery(watcherEnabled: true, cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: output,
            baseIndentation: 0
        )

        "Found {{ types.all.count }} Types".update(in: templatePath)

        func assertContinuously(
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

        assertContinuously {
            try (outputDir + Sourcery().generatedPath(for: templatePath)).read(.utf8)
        } until: {
            $0.contains("\(Sourcery.generationHeader)Found 3 Types")
        }

        _ = watcher
    }

    func test_processFiles_whenTemplateFolder_andSingleFileOutput_itJoinsGeneratedCodeIntoSingleFile() throws {
        let outputFile = outputDir + "Composed.swift"
        let expectedResult = try? (Stubs.resultDirectory + Path("Basic+Other+SourceryTemplates.swift")).read(.utf8).withoutWhitespaces

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [
                Stubs.templateDirectory + "Basic.stencil",
                Stubs.templateDirectory + "Other.stencil",
                Stubs.templateDirectory + "SourceryTemplateStencil.sourcerytemplate"
            ]),
            output: Output(outputFile),
            baseIndentation: 0
        )

        let result = try outputFile.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult?.withoutWhitespaces)
    }

    func test_processFiles_whenTemplateFolder_andSingleFileOutput_itDoesNotCreateGeneratedFileWithEmptyContent() throws {
        let outputFile = outputDir + "Composed.swift"
        let templatePath = Stubs.templateDirectory + Path("Empty.stencil")
        "".update(in: templatePath)

        _ = try Sourcery(cacheDisabled: true, prune: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [templatePath]),
            output: Output(outputFile),
            baseIndentation: 0
        )

        let result = try? outputFile.read(.utf8)
        XCTAssertNil(result)
    }

    func test_processFiles_whenTemplateFolder_andOutputDirectory_itCreatesCorrespondingOutputFileForEachTemplate() throws {
        let templateNames = ["Basic", "Other"]
        let generated = templateNames.map { outputDir + Sourcery().generatedPath(for: Stubs.templateDirectory + "\($0).stencil") }
        let expected = templateNames.map { Stubs.resultDirectory + Path("\($0).swift") }

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(include: [Stubs.templateDirectory]),
            output: output,
            baseIndentation: 0
        )

        for (idx, outputPath) in generated.enumerated() {
            let output = try outputPath.read(.utf8)
            let expected = try expected[idx].read(.utf8)

            XCTAssertEqual(output.withoutWhitespaces, expected.withoutWhitespaces)
        }
    }

    func test_processFiles_whenTemplateFolder_andExcludedTemplatePaths_itDoesNotCreateGeneratedFileForExcludedTemplates() throws {
        let outputFile = outputDir + "Composed.swift"
        let expectedResult = try (Stubs.resultDirectory + Path("Basic+Other.swift")).read(.utf8).withoutWhitespaces

        _ = try Sourcery(cacheDisabled: true).processFiles(
            .sources(Paths(include: [Stubs.sourceDirectory])),
            usingTemplates: Paths(
                include: [Stubs.templateDirectory],
                exclude: [
                    Stubs.templateDirectory + "GenerationWays.stencil",
                    Stubs.templateDirectory + "Include.stencil",
                    Stubs.templateDirectory + "Partial.stencil",
                    Stubs.templateDirectory + "SourceryTemplateStencil.sourcerytemplate"
                ]
            ),
            output: Output(outputFile), 
            baseIndentation: 0
        )

        let result = try outputFile.read(.utf8)
        XCTAssertEqual(result.withoutWhitespaces, expectedResult.withoutWhitespaces)
    }

    private func createProjectScenario(templatePath: Path) throws -> ProjectScenario {
        let projectPath = Stubs.sourceDirectory + "TestProject"
        let projectFilePath = Stubs.sourceDirectory + "TestProject/TestProject.xcodeproj"
        let sources = try Source(
            dict: [
                "project": [
                    "file": "TestProject.xcodeproj",
                    "target": ["name": "TestProject"]
                ]
            ],
            relativePath: projectPath
        )
        let templates = Paths(include: [templatePath])
        let project = try XcodeProj(path: projectFilePath)
        return .init(
            sources: sources,
            templates: templates,
            originalProject: project,
            projectPath: projectPath,
            projectFilePath: projectFilePath
        )
    }

    func test_processFiles_whenProject_itLinksGeneratedFiles() throws {
        let scenario = try createProjectScenario(templatePath: .otherStencilPath)

        _ = try Sourcery(cacheDisabled: true, prune: true).processFiles(
            scenario.sources,
            usingTemplates: scenario.templates,
            output: scenario.createOutput(at: outputDir),
            baseIndentation: 0
        )

        XCTAssertTrue(scenario.sourceFilesPaths.contains(outputDir + "Other.generated.swift"))
        XCTAssertNoThrow(try scenario.originalProject.writePBXProj(path: scenario.projectFilePath, outputSettings: .init()))
    }

    func test_processFiles_whenProject_itLinksGeneratedFilesWhenUsingPerFileGeneration() throws {
        let templatePath = outputDir + "PerFileGeneration.stencil"
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

        _ = try Sourcery(cacheDisabled: true, prune: true).processFiles(
            scenario.sources,
            usingTemplates: scenario.templates,
            output: scenario.createOutput(at: outputDir),
            baseIndentation: 0
        )

        XCTAssertTrue(scenario.sourceFilesPaths.contains(outputDir + "PerFileGeneration.generated.swift"))
        XCTAssertTrue(scenario.sourceFilesPaths.contains(outputDir + "Generated/Foo.generated.swift"))
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
    let sources: Source
    let templates: Paths
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
        try Output(
            dict: [
                "path": path.string,
                "link": ["project": "TestProject.xcodeproj", "target": "TestProject"]
            ],
            relativePath: projectPath
        )
    }
}
