import PathKit
import XCTest
@testable import SourceryKit

class ConfigurationParserTests: XCTestCase {
    var sut: ConfigurationParser!

    var pathResolverMock: PathResolverMock!
    var xcodeProjFactoryMock: XcodeProjFactoryMock!
    var xcodeProjMock: XcodeProjMock!

    override func setUp() {
        super.setUp()
        pathResolverMock = .init()
        xcodeProjMock = .init()
        xcodeProjFactoryMock = .init()
        xcodeProjFactoryMock.createReturnValue = xcodeProjMock
        sut = .init(
            pathResolver: pathResolverMock,
            xcodeProjFactory: xcodeProjFactoryMock
        )
    }

    func test_parsesConfig_whenDefaultValues() throws {
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.arguments, [:])
        XCTAssertEqual(config.baseIndentation, 0)
        XCTAssertEqual(config.cacheBasePath, .systemCachePath)
        XCTAssertEqual(config.cacheDisabled, false)
        XCTAssertEqual(config.forceParse, [])
        XCTAssertEqual(config.parseDocumentation, false)
    }

    func test_parsesConfig_whenSinglePath() throws {
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, ["/base/path/Sources"])
        XCTAssertEqual(config.templates, ["/base/path/Templates"])
        XCTAssertEqual(config.output, "/base/path/Output")
    }

    func test_parsesConfig_whenMultiplePaths() throws {
        let yaml = """
        sources:
          - Sources
        templates:
          - Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, ["/base/path/Sources"])
        XCTAssertEqual(config.templates, ["/base/path/Templates"])
    }

    func test_parsesConfig_whenIncludes() throws {
        pathResolverMock.resolveReturnValues = [["/base/path/Sources"], ["/base/path/Templates"]]
        let yaml = """
        sources:
          include:
            - Sources
        templates:
          include:
            - Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, ["/base/path/Sources"])
        XCTAssertEqual(config.templates, ["/base/path/Templates"])
        XCTAssertEqual(pathResolverMock.calls, [
            .resolve(["/base/path/Sources"], []),
            .resolve(["/base/path/Templates"], [])
        ])
    }

    func test_parsesConfig_whenIncludes_andExcludes() throws {
        pathResolverMock.resolveReturnValues = [["/base/path/Sources"], ["/base/path/Templates"]]
        let yaml = """
        sources:
          include:
            - Sources
          exclude:
            - Sources/Excluded
        templates:
          include:
            - Templates
          exclude:
            - Templates/Excluded
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, ["/base/path/Sources"])
        XCTAssertEqual(config.templates, ["/base/path/Templates"])
        XCTAssertEqual(pathResolverMock.calls, [
            .resolve(["/base/path/Sources"], ["/base/path/Sources/Excluded"]),
            .resolve(["/base/path/Templates"], ["/base/path/Templates/Excluded"])
        ])
    }

    func test_parsesConfig_whenProject() throws {
        xcodeProjMock.sourceFilesPathsReturnValue = ["fake/source/file"]
        let yaml = """
        project:
          file: FakeProject.xcodeproj
          target:
            name: FakeTarget
        templates: Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, [SourceFile(path: "fake/source/file", module: "FakeTarget")])
        XCTAssertEqual(xcodeProjFactoryMock.calls, [.create("/base/path/FakeProject.xcodeproj")])
        XCTAssertEqual(xcodeProjMock.calls, [.sourceFilesPaths("FakeTarget", "/base/path")])
    }

    func test_parsesConfig_whenProject_andAllKeys() throws {
        xcodeProjMock.sourceFilesPathsReturnValue = ["fake/source/file"]
        let yaml = """
        project:
          file: FakeProject.xcodeproj
          target:
            name: FakeTarget
            module: FakeModule
            xcframeworks:
              - FakeFramework.xcframework
          exclude:
            - FakeExclude
        templates: Templates
        output: Output
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, [SourceFile(path: "fake/source/file", module: "FakeModule")]) // TODO: fix and test xcframework
        XCTAssertEqual(xcodeProjFactoryMock.calls, [.create("/base/path/FakeProject.xcodeproj")])
        XCTAssertEqual(xcodeProjMock.calls, [.sourceFilesPaths("FakeTarget", "/base/path")])
    }

    func test_parsesConfig_whenXcode() throws {
        xcodeProjMock.sourceFilesPathsReturnValue = ["fake/source/file"]
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        xcode:
          project: FakeProject.xcodeproj
          target: FakeTarget
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.xcode, .stub(project: "/base/path/FakeProject.xcodeproj", targets: ["FakeTarget"]))
    }

    func test_parsesConfig_whenXcode_andGroup() throws {
        xcodeProjMock.sourceFilesPathsReturnValue = ["fake/source/file"]
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        xcode:
          project: FakeProject.xcodeproj
          target: FakeTarget
          group: FakeGroup
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.xcode, .stub(project: "/base/path/FakeProject.xcodeproj", targets: ["FakeTarget"], group: "FakeGroup"))
    }

    func test_parsesConfig_whenXcode_andMultipleTargets() throws {
        xcodeProjMock.sourceFilesPathsReturnValue = ["fake/source/file"]
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        xcode:
          project: FakeProject.xcodeproj
          targets:
            - FakeTarget1
            - FakeTarget2
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.xcode, .stub(project: "/base/path/FakeProject.xcodeproj", targets: ["FakeTarget1", "FakeTarget2"]))
    }

    func test_parsesConfig_whenCacheBasePath() throws {
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        cacheBasePath: fake/cache/base/path
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.cacheBasePath, "/base/path/fake/cache/base/path")
    }

    func test_parsesConfig_whenCacheDisabled() throws {
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        cacheDisabled: true
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.cacheDisabled, true)
    }

    func test_parsesConfig_whenParseDocumentation() throws {
        let yaml = """
        sources: Sources
        templates: Templates
        output: Output
        parseDocumentation: true
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.parseDocumentation, true)
    }

    func test_replacesEnvPlaceholders() throws {
        let yaml = """
        sources: ${SOURCE_PATH}
        templates: Templates
        output: Output
        args:
          serverUrl: ${serverUrl}
          serverPort: ${serverPort}
        """
        let config = try XCTUnwrap(sut.parse(from: yaml).first)
        XCTAssertEqual(config.sources, ["/base/path/Sources"])
        XCTAssertEqual(config.arguments["serverUrl"] as? String, "www.example.com")
        XCTAssertEqual(config.arguments["serverPort"] as? String, "")
    }

    func test_parsesMultipleConfigurations() throws {
        let yaml = """
        configurations:
          - sources: ${SOURCE_PATH}/0
            templates: Templates/0
            output: Output/0
            args:
              serverUrl: ${serverUrl}/0
              serverPort: ${serverPort}/0
          - sources: ${SOURCE_PATH}/1
            templates: Templates/1
            output: Output/1
            args:
              serverUrl: ${serverUrl}/1
              serverPort: ${serverPort}1
        """
        let configs = try sut.parse(from: yaml)

        XCTAssertEqual(configs.count, 2)

        for (offset, config) in configs.enumerated() {
            let configServerUrl = config.arguments["serverUrl"] as? String

            XCTAssertEqual(configServerUrl, "www.example.com/\(offset)")
            XCTAssertEqual(config.sources, [SourceFile(path: Path("/base/path/Sources/\(offset)"))])
        }
    }

    func test_failsParsing_whenInvalidFormat() {
        let yaml = "invalid"
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidFormat(message: "Expected dictionary."))
        }
    }

    func test_failsParsing_whenInvalidSources_andKeyMissing() {
        let yaml = """
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidSources(message: "Expected either 'sources' key or 'project' key."))
        }
    }

    func test_failsParsing_whenInvalidSources_andPathMissing() {
        let yaml = """
        sources:
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidSources(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidSources_andIncludeKeyMissing() {
        let yaml = """
        sources:
          exclude:
            - .
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidSources(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidSources_andIncludeValueHasWrongFormat() {
        let yaml = """
        sources:
          include: .
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidSources(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidTemplates_andKeyMissing() {
        let yaml = """
        sources: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTemplates(message: "'templates' key is missing."))
        }
    }

    func test_failsParsing_whenInvalidTemplates_andPathMissing() {
        let yaml = """
        sources: .
        templates:
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTemplates(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidTemplates_andIncludeKeyMissing() {
        let yaml = """
        sources: .
        templates:
          exclude:
            - .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTemplates(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidTemplates_andIncludeValueHasWrongFormat() {
        let yaml = """
        sources: .
        templates:
          include: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTemplates(message: "No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys."))
        }
    }

    func test_failsParsing_whenInvalidProject_andInvalidValueType() {
        let yaml = """
        project:
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidProject(message: "Expected an object."))
        }
    }

    func test_failsParsing_whenInvalidProject_andFileKeyMissing() {
        let yaml = """
        project:
          root: .
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidProject(message: "Project file path is not provided. Expected string."))
        }
    }

    func test_failsParsing_whenInvalidProject_andTargetKeyMissing() {
        let yaml = """
        project:
          file: .
          root: .
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidProject(message: "'target' key is missing."))
        }
    }

    func test_failsParsing_whenInvalidTarget_andInvalidValueType() {
        let yaml = """
        project:
          file: .
          root: .
          target:
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTarget(message: "Expected an object or an array of objects."))
        }
    }

    func test_failsParsing_whenInvalidTarget_andNameKeyMissing() {
        let yaml = """
        project:
          file: .
          root: .
          target:
            module: FakeModule
        templates: .
        output: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidTarget(message: "Target name is not provided. Expected a string."))
        }
    }

    func test_failsParsing_whenInvalidOutput_andOutputKeyMissing() {
        let yaml = """
        sources: .
        templates: .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidOutput(message: "'output' key is missing."))
        }
    }

    func test_failsParsing_whenInvalidOutput_andInvalidValueType() {
        let yaml = """
        sources: .
        templates: .
        output:
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidOutput(message: "'output' key is not a string."))
        }
    }

    func test_failsParsing_whenInvalidXcode_andInvalidValueType() {
        let yaml = """
        sources: .
        templates: .
        output: .
        xcode:
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidXcode(message: "Expected an object."))
        }
    }

    func test_failsParsing_whenInvalidCacheBasePath_andInvalidValueType() {
        let yaml = """
        sources: .
        templates: .
        output: .
        cacheBasePath:
          - .
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidCacheBasePath(message: "'cacheBasePath' key is not a string."))
        }
    }

    func test_failsParsing_whenInvalidCacheDisabled_andInvalidValueType() {
        let yaml = """
        sources: .
        templates: .
        output: .
        cacheDisabled:
        """
        assertThrowing(try sut.parse(from: yaml)) {
            XCTAssertEqual($0, .invalidCacheDisabled(message: "Expected a boolean."))
        }
    }

    func test_errorDescription() {
        typealias Error = ConfigurationParser.Error
        XCTAssertEqual(Error.invalidFormat(message: "fake").description, "Invalid config file format. fake")
        XCTAssertEqual(Error.invalidProject(message: "fake").description, "Invalid project. fake")
        XCTAssertEqual(Error.invalidSources(message: "fake").description, "Invalid sources. fake")
        XCTAssertEqual(Error.invalidTarget(message: "fake").description, "Invalid target. fake")
        XCTAssertEqual(Error.invalidXCFramework(path: "fakePath", message: "fake").description, "Invalid xcframework at path 'fakePath'. fake")
        XCTAssertEqual(Error.invalidXCFramework(path: nil, message: "fake").description, "Invalid xcframework. fake")
        XCTAssertEqual(Error.invalidTemplates(message: "fake").description, "Invalid templates. fake")
        XCTAssertEqual(Error.invalidOutput(message: "fake").description, "Invalid output. fake")
        XCTAssertEqual(Error.invalidCacheBasePath(message: "fake").description, "Invalid cacheBasePath. fake")
        XCTAssertEqual(Error.invalidCacheDisabled(message: "fake").description, "Invalid cacheDisabled. Expected a boolean, but got a fake.")
        XCTAssertEqual(Error.invalidPaths(message: "fake").description, "fake")
    }
}

private extension ConfigurationParser {
    func parse(from string: String) throws -> [Configuration] {
        try parse(from: string, basePath: .stubBasePath, env: stubEnv)
    }
}

private extension Path {
    static var stubBasePath = Path("/base/path")
}

private let stubEnv = ["SOURCE_PATH": "Sources", "serverUrl": "www.example.com"]

private extension ConfigurationParserTests {
    func assertThrowing<T>(
        _ expression: @autoclosure () throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line,
        handleError: (_ error: ConfigurationParser.Error?) -> Void
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) {
            let error = $0 as? ConfigurationParser.Error
            handleError(error)
        }
    }
}
