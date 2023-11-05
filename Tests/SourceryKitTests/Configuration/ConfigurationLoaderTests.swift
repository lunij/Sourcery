import PathKit
import XCTest
@testable import SourceryKit

class ConfigurationLoaderTests: XCTestCase {
    var sut: ConfigurationLoader!

    var fileReaderMock: FileReaderMock!
    var loggerMock: LoggerMock!
    var parserMock: ConfigurationParserMock!

    override func setUp() {
        super.setUp()
        fileReaderMock = .init()
        loggerMock = .init()
        logger = loggerMock
        parserMock = .init()
        sut = .init(parser: parserMock, fileReader: fileReaderMock, environment: ["fakeEnvKey": "fakeEnvValue"])
    }

    func test_loadsDefaultConfig_whenNoConfigFile_andNoConfigPaths() throws {
        var options = try ConfigurationOptions.parse([])
        options.configPaths = []
        let configurations = try sut.loadConfigurations(options: options)

        XCTAssertEqual(configurations, [.expectedDefault])
        XCTAssertEqual(fileReaderMock.calls, [])
        XCTAssertEqual(loggerMock.calls, [.info("No configuration files loaded. Using default configuration and command line arguments.")])
        XCTAssertEqual(parserMock.calls, [])
    }

    func test_loadsDefaultConfig_whenNoConfigFile_andDefaultConfigPath() throws {
        fileReaderMock.readError = FileReader.Error.fileNotExisting(".sourcery.yml")

        let options = try ConfigurationOptions.parse([])
        let configurations = try sut.loadConfigurations(options: options)

        XCTAssertEqual(configurations, [.expectedDefault])
        XCTAssertEqual(fileReaderMock.calls, [.read(".sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [.info("No configuration files loaded. Using default configuration and command line arguments.")])
        XCTAssertEqual(parserMock.calls, [])
    }

    func test_loadsDefaultConfig_whenConfigFile_andParserReturnsNoConfigs() throws {
        fileReaderMock.readReturnValue = "fake"
        parserMock.parseReturnValue = []

        let options = try ConfigurationOptions.parse([])
        let configurations = try sut.loadConfigurations(options: options)

        XCTAssertEqual(configurations, [.expectedDefault])
        XCTAssertEqual(fileReaderMock.calls, [.read(".sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [
            .info("Loading configuration file at .sourcery.yml"),
            .info("No configuration files loaded. Using default configuration and command line arguments.")
        ])
        XCTAssertEqual(parserMock.calls, [.parse("fake", ".", ["fakeEnvKey": "fakeEnvValue"])])
    }

    func test_loadsConfig() throws {
        fileReaderMock.readReturnValue = "fake"
        parserMock.parseReturnValue = [.stub()]

        let options = try ConfigurationOptions.parse([])
        let configurations = try sut.loadConfigurations(options: options)

        XCTAssertEqual(configurations, [.stub()])
        XCTAssertEqual(fileReaderMock.calls, [.read(".sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [.info("Loading configuration file at .sourcery.yml")])
        XCTAssertEqual(parserMock.calls, [.parse("fake", ".", ["fakeEnvKey": "fakeEnvValue"])])
    }

    func test_loadsConfig_whenConfigPathIsAFilePath() throws {
        fileReaderMock.readReturnValue = "fake"
        parserMock.parseReturnValue = [.stub()]

        let options = try ConfigurationOptions.parse(["--config", ".sourcery.yml"])
        let configurations = try sut.loadConfigurations(options: options)

        XCTAssertEqual(configurations, [.stub()])
        XCTAssertEqual(fileReaderMock.calls, [.read(".sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [.info("Loading configuration file at .sourcery.yml")])
        XCTAssertEqual(parserMock.calls, [.parse("fake", ".", ["fakeEnvKey": "fakeEnvValue"])])
    }

    func test_failsLoadingConfig_whenFileNotExisting_andNonDefaultConfigPath() throws {
        fileReaderMock.readError = FileReader.Error.fileNotExisting("fakePath/.sourcery.yml")

        let options = try ConfigurationOptions.parse(["--config", "fakePath"])

        XCTAssertThrowsError(try sut.loadConfigurations(options: options)) { error in
            let error = error as? FileReader.Error
            XCTAssertEqual(error, .fileNotExisting("fakePath/.sourcery.yml"))
        }
        XCTAssertEqual(fileReaderMock.calls, [.read("fakePath/.sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [])
        XCTAssertEqual(parserMock.calls, [])
    }

    func test_failsLoadingConfig_whenAnyOtherError() throws {
        fileReaderMock.readError = StubError()

        let options = try ConfigurationOptions.parse([])

        XCTAssertThrowsError(try sut.loadConfigurations(options: options)) { error in
            XCTAssertNotNil(error as? StubError)
        }
        XCTAssertEqual(fileReaderMock.calls, [.read(".sourcery.yml", .utf8)])
        XCTAssertEqual(loggerMock.calls, [])
        XCTAssertEqual(parserMock.calls, [])
    }
}

private extension Configuration {
    static var expectedDefault: Self {
        .init(
            sources: [],
            templates: [],
            output: ".",
            xcode: nil,
            cacheBasePath: .systemCachePath,
            cacheDisabled: false,
            forceParse: [],
            parseDocumentation: false,
            arguments: [:]
        )
    }
}
