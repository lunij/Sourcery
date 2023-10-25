import PathKit
import SourceryRuntime
import XCTest
@testable import SourceryKit

class SwiftParserTests: XCTestCase {
    var sut: SwiftParser!

    var output: Output!

    var loggerMock: LoggerMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        loggerMock = .init()
        logger = loggerMock
        output = try .init(.createTestDirectory(suffixed: "SwiftParserTests"))
        sut = .init()
    }

    func test_parsesNothing_whenNoSources() throws {
        let parsingResult = try sut.parseSources(from: .stub(), cacheDisabled: true)

        XCTAssertEqual(parsingResult.parserResult, nil)
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(types: [], typealiases: []))
        XCTAssertTrue(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [.info("Found 0 types in 0 files.")])
    }

    func test_parses_whenCacheDisabled() throws {
        let sourcePath = output.path + Path("Source.swift")

        """
        struct Fake {
            let fakeInt: Int
        }
        """.update(in: sourcePath)

        let parsingResult = try sut.parseSources(from: .stub(sources: .paths(.init(include: [sourcePath]))), cacheDisabled: true)

        XCTAssertEqual(parsingResult.parserResult, nil)
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(
            types: [
                Struct(
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
            ],
            typealiases: []
        ))
        XCTAssertFalse(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [.info("Found 1 type in 1 file.")])
    }

    func test_parses_whenCacheEnabled() throws {
        let sourcePath = output.path + Path("Source.swift")

        """
        struct Fake {
            let fakeInt: Int
        }
        """.update(in: sourcePath)

        let parsingResult = try sut.parseSources(from: .stub(sources: .paths(.init(include: [sourcePath]))), cacheDisabled: false)

        XCTAssertEqual(parsingResult.parserResult, nil)
        XCTAssertEqual(parsingResult.functions, [])
        XCTAssertEqual(parsingResult.types, Types(
            types: [
                Struct(
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
            ],
            typealiases: []
        ))
        XCTAssertFalse(parsingResult.inlineRanges.isEmpty)
        XCTAssertEqual(loggerMock.calls, [
            .info("Found 1 type in 1 file."),
            .info("1 file changed from last run.")
        ])
    }

    func test_failsParsing_whenContainingMergeConflictMarkers() {
        let sourcePath = output.path + Path("Source.swift")

        """


        <<<<<

        """.update(in: sourcePath)

        XCTAssertThrowsError(try sut.parseSources(
            from: .stub(
                sources: .paths(Paths(include: [sourcePath])),
                templates: Paths(include: [.basicStencilPath]),
                output: output
            ),
            cacheDisabled: true
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
        methods: [SourceryRuntime.Method] = [],
        subscripts: [Subscript] = [],
        inheritedTypes: [String] = [],
        containedTypes: [Type] = [],
        typealiases: [Typealias] = [],
        attributes: AttributeList = [:],
        modifiers: [SourceryModifier] = [],
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
