import PathKit
import XCTest
@testable import SourceryKit

class ConfigurationParserTests: XCTestCase {
    var sut: ConfigurationParser!

    let relativePath = Path("/some/path")
    let env = ["SOURCE_PATH": "Sources", "serverUrl": "www.example.com"]

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    func test_replacesEnvPlaceholders() throws {
        let yaml = """
        sources:
          - "${SOURCE_PATH}"
        templates:
          - "Templates"
        output: "Output"
        args:
          serverUrl: ${serverUrl}
          serverPort: ${serverPort}
        """
        let config = try sut.parse(from: yaml, relativePath: relativePath, env: env)
        guard case let .paths(paths) = config.sources else {
            return XCTFail("Config has no source paths")
        }

        XCTAssertEqual(paths.include, ["/some/path/Sources"])
        XCTAssertEqual(config.arguments["serverUrl"] as? String, "www.example.com")
        XCTAssertEqual(config.arguments["serverPort"] as? String, "")
    }

    func test_multipleConfigurations() throws {
        let yaml = """
        configurations:
          - sources:
              - "${SOURCE_PATH}/0"
            templates:
              - "Templates/0"
            output: "Output/0"
            args:
              serverUrl: "${serverUrl}/0"
              serverPort: "${serverPort}/0"
          - sources:
              - "${SOURCE_PATH}/1"
            templates:
              - "Templates/1"
            output: "Output/1"
            args:
              serverUrl: "${serverUrl}/1"
              serverPort: "${serverPort}1"
        """
        let configs = try sut.parseConfigurations(from: yaml, relativePath: relativePath, env: env)

        XCTAssertEqual(configs.count, 2)

        configs.enumerated().forEach { offset, config in
            guard case let .paths(paths) = config.sources,
                  let path = paths.include.first
            else {
                XCTFail("Config has no Source Paths")
                return
            }

            let configServerUrl = config.arguments["serverUrl"] as? String

            XCTAssertEqual(configServerUrl, "www.example.com/\(offset)")
            XCTAssertEqual(path, Path("/some/path/Sources/\(offset)"))
        }
    }

    func configError(_ config: [String: Any]) -> String {
        do {
            _ = try sut.parse(dict: config, relativePath: relativePath)
            return "No error"
        } catch {
            return "\(error)"
        }
    }

    func test_invalidConfig_throwsOnInvalidFileFormat() {
        do {
            _ = try sut.parse(from: "invalid configuration", relativePath: relativePath, env: [:])
            XCTFail("expected to throw error")
        } catch {
            XCTAssertEqual("\(error)", "Invalid config file format. Expected dictionary.")
        }
    }

    func test_invalidConfig_throwsOnEmptySources() {
        let config: [String: Any] = ["sources": [], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No paths provided.")
    }

    func test_invalidConfig_throwsOnMissingSources() {
        let config: [String: Any] = ["templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. 'sources' or 'project' key are missing.")
    }

    func test_invalidConfig_throwsOnInvalidSourcesFormat() {
        let config: [String: Any] = ["sources": ["inc": ["."]], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
    }

    func test_invalidConfig_throwsOnMissingSourcesIncludeKey() {
        let config: [String: Any] = ["sources": ["exclude": ["."]], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
    }

    func test_invalidConfig_throwsOnInvalidSourcesIncludeFormat() {
        let config: [String: Any] = ["sources": ["include": "."], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
    }

    func test_invalidConfig_throwsOnMissingTemplatesKey() {
        let config: [String: Any] = ["sources": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid templates. 'templates' key is missing.")
    }

    func test_invalidConfig_throwsOnEmptyTemplates() {
        let config: [String: Any] = ["sources": ["."], "templates": [], "output": "."]
        XCTAssertEqual(configError(config), "Invalid templates. No paths provided.")
    }

    func test_invalidConfig_throwsOnMissingTemplateIncludeKey() {
        let config: [String: Any] = ["sources": ["."], "templates": ["exclude": ["."]], "output": "."]
        XCTAssertEqual(configError(config), "Invalid templates. No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
    }

    func test_invalidConfig_throwsOnInvalidTemplateIncludeFormat() {
        let config: [String: Any] = ["sources": ["."], "templates": ["include": "."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid templates. No paths provided. Expected list of strings or object with 'include' and optional 'exclude' keys.")
    }

    func test_invalidConfig_throwsOnEmptyProjects() {
        let config: [String: Any] = ["project": [], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No projects provided.")
    }

    func test_invalidConfig_throwsOnMissingProjectFile() {
        let config: [String: Any] = ["project": ["root": "."], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. Project file path is not provided. Expected string.")
    }

    func test_invalidConfig_throwsOnMissingTargetKey() {
        let config: [String: Any] = ["project": ["file": ".", "root": "."], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. 'target' key is missing. Expected object or array of objects.")
    }

    func test_invalidConfig_throwsOnEmptyTargets() {
        let config: [String: Any] = ["project": ["file": ".", "root": ".", "target": []], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. No targets provided.")
    }

    func test_invalidConfig_throwsOnMissingTargetNameKey() {
        let config: [String: Any] = ["project": ["file": ".", "root": ".", "target": ["module": "module"]], "templates": ["."], "output": "."]
        XCTAssertEqual(configError(config), "Invalid sources. Target name is not provided. Expected string.")
    }

    func test_invalidConfig_throwsOnMissingOutputKey() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."]]
        XCTAssertEqual(configError(config), "Invalid output. 'output' key is missing or is not a string or object.")
    }

    func test_invalidConfig_throwsOnInvalidOutputFormat() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": ["."]]
        XCTAssertEqual(configError(config), "Invalid output. 'output' key is missing or is not a string or object.")
    }

    func test_invalidConfig_throwsOnInvalidCacheBasePathFormat() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": ".", "cacheBasePath": ["."]]
        XCTAssertEqual(configError(config), "Invalid cacheBasePath. 'cacheBasePath' key is not a string.")
    }

    func test_source_providesSourcesPathsAsArray() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": "."]
        let sources = try? sut.parse(dict: config, relativePath: relativePath).sources
        XCTAssertEqual(sources, .paths(Paths(include: [relativePath])))
    }

    func test_source_includePathsProvidedWithIncludeKey() {
        let config: [String: Any] = ["sources": ["include": ["."]], "templates": ["."], "output": "."]
        let sources = try? sut.parse(dict: config, relativePath: relativePath).sources
        XCTAssertEqual(sources, .paths(Paths(include: [relativePath])))
    }

    func test_source_excludePathsProvidedWithTheExcludeKey() {
        let config: [String: Any] = ["sources": ["include": ["."], "exclude": ["excludedPath"]], "templates": ["."], "output": "."]
        let sources = try? sut.parse(dict: config, relativePath: relativePath).sources
        XCTAssertEqual(sources, .paths(Paths(include: [relativePath], exclude: [relativePath + "excludedPath"])))
    }

    func test_templates_includePathsProvidedAsArray() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": "."]
        let templates = try? sut.parse(dict: config, relativePath: relativePath).templates
        let expected = Paths(include: [relativePath])
        XCTAssertEqual(templates, expected)
    }

    func test_templates_includePathsProvidedWithIncludeKey() {
        let config: [String: Any] = ["sources": ["."], "templates": ["include": ["."]], "output": "."]
        let templates = try? sut.parse(dict: config, relativePath: relativePath).templates
        let expected = Paths(include: [relativePath])
        XCTAssertEqual(templates, expected)
    }

    func test_templates_excludePathsProvidedWithTheExcludeKey() {
        let config: [String: Any] = ["sources": ["."], "templates": ["include": ["."], "exclude": ["excludedPath"]], "output": "."]
        let templates = try? sut.parse(dict: config, relativePath: relativePath).templates
        let expected = Paths(include: [relativePath], exclude: [relativePath + "excludedPath"])
        XCTAssertEqual(templates, expected)
    }

    func test_cacheBasePath() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": ".", "cacheBasePath": "test-base-path"]
        let cacheBasePath = try? sut.parse(dict: config, relativePath: relativePath).cacheBasePath
        let expected = Path("test-base-path", relativeTo: relativePath)
        XCTAssertEqual(cacheBasePath, expected)
    }

    func test_parseDocumentation_whenTrue() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": ".", "parseDocumentation": true]
        let parseDocumentation = try? sut.parse(dict: config, relativePath: relativePath).parseDocumentation
        let expected = true
        XCTAssertEqual(parseDocumentation, expected)
    }

    func test_parseDocumentation_whenFalse_orUnset() {
        let config: [String: Any] = ["sources": ["."], "templates": ["."], "output": "."]
        let parseDocumentation = try? sut.parse(dict: config, relativePath: relativePath).parseDocumentation
        let expected = false
        XCTAssertEqual(parseDocumentation, expected)
    }
}
