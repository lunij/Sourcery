
import PathKit
import XCTest

class SystemTests: XCTestCase {
    override func setUp() {
        super.setUp()
        deleteOutputDirectory()
    }

    func test_autoCasesTemplate() {
        runSourcery(template: "AutoCases")
        assert(template: "AutoCases")
    }

    func test_autoEquatableTemplate() {
        runSourcery(template: "AutoEquatable")
        assert(template: "AutoEquatable")
    }

    func test_autoHashableTemplate() {
        runSourcery(template: "AutoHashable")
        assert(template: "AutoHashable")
    }

    func test_autoLensesTemplate() {
        runSourcery(template: "AutoLenses")
        assert(template: "AutoLenses")
    }

    func test_autoMockableTemplate() {
        runSourcery(template: "AutoMockable")
        assert(template: "AutoMockable")
    }

    func test_linuxMainTemplate() {
        runSourcery(template: "LinuxMain")
        assert(template: "LinuxMain")
    }

    func test_autoCodableTemplate() {
        runSourcery(template: "AutoCodable", extension: "swifttemplate")
        assert(template: "AutoCodable")
    }
}

private func deleteOutputDirectory() {
    let outputDirectory = Bundle.module.unwrappedResourcePath + "Generated"
    try? outputDirectory.delete()
}

private func runSourcery(template name: String, extension: String = "stencil", file: StaticString = #filePath, line: UInt = #line) {
    do {
        let resourcePath = Bundle.module.unwrappedResourcePath
        let (exitCode, output, error) = try SourceryRunner().run(args: [
            "--sources",
            "\(resourcePath)/Context/\(name).swift",
            "--templates",
            "\(resourcePath)/Templates/\(name).\(`extension`)",
            "--output",
            "\(resourcePath)/Generated/\(name).generated.swift",
            "--no-cache",
            "--verbose"
        ])

        XCTAssertEqual(exitCode, 0, file: file, line: line)
        XCTAssertFalse(output.isEmpty, file: file, line: line)
        XCTAssertEqual(error, "", file: file, line: line)
    } catch {
        XCTFail(String(describing: error), file: file, line: line)
    }
}

private func assert(template name: String, file: StaticString = #filePath, line: UInt = #line) {
    let generatedFilePath = "Generated/\(name).generated.swift".relativeToResourcePath
    let expectedFilePath = "Expected/\(name).expected.swift".relativeToResourcePath

    guard generatedFilePath.exists else {
        return XCTFail("File \(generatedFilePath.lastComponent) not found\n\(generatedFilePath)", file: file, line: line)
    }
    guard expectedFilePath.exists else {
        return XCTFail("File \(expectedFilePath.lastComponent) not found\n\(expectedFilePath)", file: file, line: line)
    }
    guard let generatedFileContent = try? generatedFilePath.read(.utf8) else {
        return XCTFail("File \(generatedFilePath.lastComponent) could not be read\n\(generatedFilePath)", file: file, line: line)
    }
    guard let expectedFileContent = try? expectedFilePath.read(.utf8) else {
        return XCTFail("File \(expectedFilePath.lastComponent) could not be read\n\(expectedFilePath)", file: file, line: line)
    }

    let emptyLinesFilter: (String) -> Bool = { line in return !line.isEmpty }
    let commentLinesFilter: (String) -> Bool = { line in return !line.hasPrefix("//") }
    let generatedFileLines = generatedFileContent.components(separatedBy: .newlines).filter(emptyLinesFilter)
    let generatedFileFilteredLines = generatedFileLines.filter(emptyLinesFilter).filter(commentLinesFilter)
    let expectedFileLines = expectedFileContent.components(separatedBy: .newlines)
    let expectedFileFilteredLines = expectedFileLines.filter(emptyLinesFilter).filter(commentLinesFilter)

    XCTAssertEqual(generatedFileFilteredLines, expectedFileFilteredLines, file: file, line: line)
}

private extension Bundle {
    var unwrappedResourcePath: Path {
        Path(resourcePath!)
    }
}

private extension String {
    var relativeToResourcePath: Path {
        Bundle.module.unwrappedResourcePath + self
    }
}

private final class SourceryRunner {
    let sourceryPath: Path

    init() {
        let buildDir = if let xcTestBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"] { // Xcode + SPM
            Path(xcTestBundlePath).parent()
        } else { // SPM only
            Path(Bundle.module.bundlePath).parent()
        }
        sourceryPath = buildDir + "sourcery"
    }

    func run(args: [String]) throws -> (Int32, String, String) {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = sourceryPath.url
        process.arguments = args
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let exitCode = process.terminationStatus
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        return (exitCode, output, error)
    }
}
