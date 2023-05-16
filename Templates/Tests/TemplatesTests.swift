import Foundation
import PathKit
import XCTest

class TemplatesTests: XCTestCase {
    override class func setUp() {
        super.setUp()

        print("Generating sources...", terminator: " ")

        let buildDir: Path
        // Xcode + SPM
        if let xcTestBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"] {
            buildDir = Path(xcTestBundlePath).parent()
        } else {
            // SPM only
            buildDir = Path(Bundle.module.bundlePath).parent()
        }
        let sourcery = buildDir + "sourcery"

        let resources = Bundle.module.resourcePath!

        let outputDirectory = Path(resources) + "Generated"
        if outputDirectory.exists {
            do {
                try outputDirectory.delete()
            } catch {
                print(error)
            }
        }

        var output: String?
        buildDir.chdir {
            output = launch(
                sourceryPath: sourcery,
                args: [
                    "--sources",
                    "\(resources)/Context",
                    "--templates",
                    "\(resources)/Templates",
                    "--output",
                    "\(resources)/Generated",
                    "--disableCache",
                    "--verbose"
                ]
            )
        }

        if let output = output {
            print(output)
        } else {
            print("Done!")
        }
    }

    func test_autoCasesTemplate() {
        check(template: "AutoCases")
    }

    func test_autoEquatableTemplate() {
        check(template: "AutoEquatable")
    }

    func test_autoHashableTemplate() {
        check(template: "AutoHashable")
    }

    func test_autoLensesTemplate() {
        check(template: "AutoLenses")
    }

    func test_autoMockableTemplate() {
        check(template: "AutoMockable")
    }

    func test_linuxMainTemplate() {
        check(template: "LinuxMain")
    }

    func test_autoCodableTemplate() {
        check(template: "AutoCodable")
    }

    private func check(template name: String) {
        guard let generatedFilePath = path(forResource: "\(name).generated", ofType: "swift", in: "Generated") else {
            fatalError("Template \(name) can not be checked as the generated file is not presented in the bundle")
        }
        guard let expectedFilePath = path(forResource: name, ofType: "expected", in: "Expected") else {
            fatalError("Template \(name) can not be checked as the expected file is not presented in the bundle")
        }
        guard let generatedFileString = try? String(contentsOfFile: generatedFilePath) else {
            fatalError("Template \(name) can not be checked as the generated file can not be read")
        }
        guard let expectedFileString = try? String(contentsOfFile: expectedFilePath) else {
            fatalError("Template \(name) can not be checked as the expected file can not be read")
        }

        let emptyLinesFilter: (String) -> Bool = { line in return !line.isEmpty }
        let commentLinesFilter: (String) -> Bool = { line in return !line.hasPrefix("//") }
        let generatedFileLines = generatedFileString.components(separatedBy: .newlines).filter(emptyLinesFilter)
        let generatedFileFilteredLines = generatedFileLines.filter(emptyLinesFilter).filter(commentLinesFilter)
        let expectedFileLines = expectedFileString.components(separatedBy: .newlines)
        let expectedFileFilteredLines = expectedFileLines.filter(emptyLinesFilter).filter(commentLinesFilter)

        XCTAssertEqual(generatedFileFilteredLines, expectedFileFilteredLines)
    }

    private func path(forResource name: String, ofType ext: String, in dirName: String) -> String? {
        if let resources = Bundle.module.resourcePath {
            return resources + "/\(dirName)/\(name).\(ext)"
        }
        return nil
    }

    private static func launch(sourceryPath: Path, args: [String]) -> String? {
        let process = Process()
        let output = Pipe()

        process.launchPath = sourceryPath.string
        process.arguments = args
        process.standardOutput = output
        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return nil
            }

            return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        } catch {
            return "error: can't run Sourcery from the \(sourceryPath.parent().string)"
        }
    }
}
