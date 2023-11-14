import PathKit
import XCTest
@testable import SourceryKit

class SwiftParserTests: XCTestCase {
    var sut: SwiftParser!

    var output: Path!

    var loggerMock: LoggerMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        loggerMock = .init()
        logger = loggerMock
        output = try Path.createTestDirectory(suffixed: "SwiftParserTests")
        sut = .init()
    }

    func test_parsesNothing_whenNoSources() throws {
        let parsingResult = try sut.parseSources(from: .stub())

        XCTAssertEqual(parsingResult.parserResult, .stub(modifiedDate: parsingResult.parserResult.modifiedDate))
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(types: [], typealiases: []))
        XCTAssertTrue(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [.info("Found 0 types in 0 files.")])
    }

    func test_parses_whenCacheDisabled() throws {
        let sourcePath = output + Path("Source.swift")
        let parsedStruct = Struct(
            name: "Fake",
            variables: [
                Variable(
                    name: "fakeInt",
                    typeName: .Int,
                    accessLevel: (.internal, .none),
                    definedInTypeName: .init(name: "Fake")
                )
            ],
            fileName: "Source.swift"
        )

        """
        struct Fake {
            let fakeInt: Int
        }
        """.update(in: sourcePath)

        let parsingResult = try sut.parseSources(from: .stub(sources: [SourceFile(path: sourcePath)]))

        XCTAssertEqual(parsingResult.parserResult, .stub(types: [parsedStruct], modifiedDate: parsingResult.parserResult.modifiedDate))
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(types: [parsedStruct], typealiases: []))
        XCTAssertFalse(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [.info("Found 1 type in 1 file.")])
    }

    func test_parses_whenCacheEnabled() throws {
        let sourcePath = output + Path("Source.swift")
        let parsedStruct = Struct(
            name: "Fake",
            variables: [
                Variable(
                    name: "fakeInt",
                    typeName: .Int,
                    accessLevel: (.internal, .none),
                    definedInTypeName: .init(name: "Fake")
                )
            ],
            fileName: "Source.swift"
        )

        """
        struct Fake {
            let fakeInt: Int
        }
        """.update(in: sourcePath)

        let parsingResult = try sut.parseSources(from: .stub(sources: [SourceFile(path: sourcePath)], cacheDisabled: false))

        XCTAssertEqual(parsingResult.parserResult, .stub(types: [parsedStruct], modifiedDate: parsingResult.parserResult.modifiedDate))
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(types: [parsedStruct], typealiases: []))
        XCTAssertFalse(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [
            .info("Found 1 type in 1 file."),
            .info("1 file changed from last run.")
        ])
    }

    func test_failsParsing_whenContainingMergeConflictMarkers() {
        let sourceFile = SourceFile(path: output + Path("Source.swift"))

        """


        <<<<<

        """.update(in: sourceFile.path)

        XCTAssertThrowsError(try sut.parseSources(
            from: .stub(
                sources: [sourceFile],
                templates: [.basicStencilPath],
                output: output
            )
        )) {
            let error = $0 as? SwiftParser.Error
            XCTAssertEqual(error, .containsMergeConflictMarkers)
        }
    }
}

private extension Path {
    static let basicStencilPath = Stubs.templateDirectory + Path("Basic.stencil")
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

extension Struct {
    public convenience init(
        name: String = "",
        parent: Type? = nil,
        accessLevel: AccessLevel = .internal,
        isExtension: Bool = false,
        variables: [Variable] = [],
        methods: [Function] = [],
        subscripts: [Subscript] = [],
        inheritedTypes: [String] = [],
        containedTypes: [Type] = [],
        typealiases: [Typealias] = [],
        attributes: AttributeList = [:],
        modifiers: [Modifier] = [],
        annotations: [String: NSObject] = [:],
        documentation: [String] = [],
        isGeneric: Bool = false,
        fileName: String?
    ) {
        self.init(
            name: name,
            parent: parent,
            accessLevel: accessLevel,
            isExtension: isExtension,
            variables: variables,
            methods: methods,
            subscripts: subscripts,
            inheritedTypes: inheritedTypes,
            containedTypes: containedTypes,
            typealiases: typealiases,
            attributes: attributes,
            modifiers: modifiers,
            annotations: annotations,
            documentation: documentation,
            isGeneric: isGeneric
        )
        self.fileName = fileName
    }
}
