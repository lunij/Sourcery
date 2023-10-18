import Foundation
import PathKit
import SourceryRuntime

private struct ProcessResult {
    let output: String
    let error: String
    let exitCode: Int32
}

open class SwiftTemplate {
    public let sourcePath: Path
    let buildPath: Path?
    let cachePath: Path?
    let code: String
    let version: String?
    let includedFiles: [Path]

    private lazy var buildDir: Path = {
        let path = "SwiftTemplate" + (version.map { "/\($0)" } ?? "")

        if let buildPath {
            return (buildPath + path).absolute()
        }

        return Path(FileManager.default.temporaryDirectory.appendingPathComponent(path).path)
    }()

    public init(path: Path, cachePath: Path? = nil, version: String? = nil, buildPath: Path? = nil) throws {
        sourcePath = path
        self.buildPath = buildPath
        self.cachePath = cachePath
        self.version = version
        (code, includedFiles) = try SwiftTemplate.renderGeneratorCode(sourcePath: path)
    }

    enum Command: Equatable {
        case include(Path, line: Int) // TODO: line should not be here
        case output(String)
        case controlFlow(String)
        case outputEncoded(String)
    }

    static func renderGeneratorCode(sourcePath: Path) throws -> (String, [Path]) {
        let commands = try SwiftTemplateParser().parse(file: sourcePath)

        var includedFiles: [Path] = []
        var outputFile: [String] = []
        for command in commands {
            switch command {
            case let .include(path, _):
                includedFiles.append(path)
            case let .output(code):
                outputFile.append("print(\"\\(" + code + ")\", terminator: \"\")")
            case let .controlFlow(code):
                outputFile.append("\(code)")
            case let .outputEncoded(code):
                if !code.isEmpty {
                    outputFile.append("print(\"" + code.stringEncoded + "\", terminator: \"\")")
                }
            }
        }

        let contents = outputFile.joined(separator: "\n")
        let code = """
        import Foundation
        import SourceryRuntime

        let context = try ProcessInfo().unarchiveContext()!
        let types = context.types
        let functions = context.functions
        let type = context.types.typesByName
        let argument = context.argument

        \(contents)
        """

        return (code, includedFiles)
    }

    public func render(_ context: Any) throws -> String {
        let binaryPath: Path

        if let cachePath = cachePath,
           let hash = cacheKey,
           let hashPath = hash.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
        {
            binaryPath = cachePath + hashPath
            if !binaryPath.exists {
                try? cachePath.delete() // clear old cache
                try cachePath.mkdir()
                try build().move(binaryPath)
            }
        } else {
            try binaryPath = build()
        }

        let serializedContextPath = buildDir + "context.bin"
        let data = try NSKeyedArchiver.archivedData(withRootObject: context, requiringSecureCoding: false)
        if !buildDir.exists {
            try buildDir.mkpath()
        }
        try serializedContextPath.write(data)

        let result = try Process.runCommand(path: binaryPath.description,
                                            arguments: [serializedContextPath.description])
        if !result.error.isEmpty {
            throw "\(sourcePath): \(result.error)"
        }
        return result.output
    }

    func build() throws -> Path {
        let sourcesDir = buildDir + Path("Sources")
        let templateFilesDir = sourcesDir + Path("SwiftTemplate")
        let mainFile = templateFilesDir + Path("main.swift")
        let manifestFile = buildDir + Path("Package.swift")

        try sourcesDir.mkpath()
        try? templateFilesDir.delete()
        try templateFilesDir.mkpath()

        try copyRuntimePackage(to: sourcesDir)
        if !manifestFile.exists {
            try manifestFile.write(manifestCode)
        }
        try mainFile.write(code)

        let binaryFile = buildDir + Path(".build/release/SwiftTemplate")

        try includedFiles.forEach { includedFile in
            try includedFile.copy(templateFilesDir + Path(includedFile.lastComponent))
        }

        let arguments = [
            "xcrun",
            "--sdk", "macosx",
            "swift",
            "build",
            "-c", "release",
            "-Xswiftc", "-suppress-warnings",
            "--disable-sandbox",
        ]
        let compilationResult = try Process.runCommand(path: "/usr/bin/env",
                                                       arguments: arguments,
                                                       currentDirectoryPath: buildDir)

        if compilationResult.exitCode != EXIT_SUCCESS {
            throw [compilationResult.output, compilationResult.error]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }

        return binaryFile
    }

    private var manifestCode: String {
        """
        // swift-tools-version:5.7
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        let package = Package(
            name: "SwiftTemplate",
            products: [
                .executable(name: "SwiftTemplate", targets: ["SwiftTemplate"])
            ],
            targets: [
                .target(name: "SourceryRuntime"),
                .executableTarget(name: "SwiftTemplate", dependencies: ["SourceryRuntime"])
            ]
        )
        """
    }

    var cacheKey: String? {
        var contents = code

        // For every included file, make sure that the path and modification date are included in the key
        let files = (includedFiles + buildDir.allPaths).map { $0.absolute() }.sorted(by: { $0.string < $1.string })
        for file in files {
            let hash = (try? file.read().sha256().base64EncodedString()) ?? ""
            contents += "\n// \(file.string)-\(hash)"
        }

        return contents.sha256()
    }

    private func copyRuntimePackage(to path: Path) throws {
        try FolderSynchronizer().sync(files: sourceryRuntimeFiles, to: path + Path("SourceryRuntime"))
    }
}

private extension SwiftTemplate {
    static var frameworksPath: Path {
        Path(Bundle(for: SwiftTemplate.self).bundlePath + "/Versions/Current/Frameworks")
    }
}

private extension String {
    var stringEncoded: String {
        unicodeScalars.map { x -> String in
            x.escaped(asASCII: true)
        }.joined(separator: "")
    }
}

private extension Process {
    static func runCommand(path: String, arguments: [String], currentDirectoryPath: Path? = nil) throws -> ProcessResult {
        let task = Process()
        var environment = ProcessInfo.processInfo.environment

        // https://stackoverflow.com/questions/67595371/swift-package-calling-usr-bin-swift-errors-with-failed-to-open-macho-file-to
        if ProcessInfo.processInfo.environment.keys.contains("OS_ACTIVITY_DT_MODE") {
            environment = ProcessInfo.processInfo.environment
            environment["OS_ACTIVITY_DT_MODE"] = nil
        }

        task.launchPath = path
        task.environment = environment
        task.arguments = arguments
        if let currentDirectoryPath = currentDirectoryPath {
            if #available(OSX 10.13, *) {
                task.currentDirectoryURL = currentDirectoryPath.url
            } else {
                task.currentDirectoryPath = currentDirectoryPath.description
            }
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        let outHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading

        logger.verbose(path + " " + arguments.map { "\"\($0)\"" }.joined(separator: " "))
        task.launch()

        let outputData = outHandle.readDataToEndOfFile()
        let errorData = errorHandle.readDataToEndOfFile()
        outHandle.closeFile()
        errorHandle.closeFile()

        task.waitUntilExit()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""

        return ProcessResult(output: output, error: error, exitCode: task.terminationStatus)
    }
}

struct FolderSynchronizer {
    struct File {
        let name: String
        let content: String
    }

    func sync(files: [File], to dir: Path) throws {
        if dir.exists {
            let synchronizedPaths = files.map { dir + Path($0.name) }
            try dir.children().forEach { path in
                if synchronizedPaths.contains(path) {
                    return
                }
                try path.delete()
            }
        } else {
            try dir.mkpath()
        }
        try files.forEach { file in
            let filePath = dir + Path(file.name)
            try filePath.write(file.content)
        }
    }
}
