#!/usr/bin/env swift
/// Usage: $0 FOLDER
/// Description:
///   Merge all Swift files contained in FOLDER into swift code that can be used by the FolderSynchronizer.
/// Example: $0 Sources/SourceryRuntime > file.swift
/// Options:
///   FOLDER: the path where the Swift files to merge are
///   -h: Display this help message
import Foundation

func printUsage() {
    guard let scriptPath = CommandLine.arguments.first else {
        fatalError("Could not find script path in arguments (\(CommandLine.arguments))")
    }
    guard let lines = (try? String(contentsOfFile: scriptPath, encoding: .utf8))?
        .components(separatedBy: .newlines)
    else {
        fatalError("Could not read the script at path \(scriptPath)")
    }
    let documentationPrefix = "/// "
    lines
        .filter { $0.hasPrefix(documentationPrefix) }
        .map { $0.dropFirst(documentationPrefix.count) }
        .map { $0.replacingOccurrences(of: "$0", with: scriptPath) }
        .forEach { print("\($0)") }
}

func package(folder folderPath: String) throws {
    print("let sourceryRuntimeFiles: [FolderSynchronizer.File] = [")
    let folderURL = URL(fileURLWithPath: folderPath)

    guard let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
        print("Unable to retrieve file enumerator")
        exit(1)
    }
    var files = [URL]()
    for case let fileURL as URL in enumerator {
        do {
            let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if fileAttributes.isRegularFile!, fileURL.pathExtension == "swift" {
                files.append(fileURL)
            }
        } catch {
            print(error, fileURL)
        }
    }

    let content = try files
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
        .map { sourceFileURL in
            let sourceFileContent = try String(contentsOf: sourceFileURL, encoding: .utf8)
            return """
                .init(
                    name: \"\(sourceFileURL.lastPathComponent)\",
                    content:
                    #\"\"\"
            \(sourceFileContent.indentated(by: .spaces(8)))
                    \"\"\"#
                )
            """
        }
        .joined(separator: ",\n")

    print(content)
    print("]")
}

enum Indentation: CustomStringConvertible {
    case spaces(Int)
    case tabs(Int)

    var description: String {
        switch self {
        case let .spaces(count):
            String(repeating: " ", count: count)
        case let .tabs(count):
            String(repeating: "\t", count: count)
        }
    }
}

extension String {
    func indentated(by indentation: Indentation) -> String {
        components(separatedBy: .newlines).map {
            if $0.isEmpty { return "" }
            return "\(indentation)\($0)"
        }.joined(separator: "\n")
    }
}

func main() {
    if CommandLine.arguments.contains("-h") {
        printUsage()
        exit(0)
    }
    guard CommandLine.arguments.count > 1 else {
        print("Missing folderPath argument")
        exit(1)
    }
    let folder = CommandLine.arguments[1]

    do {
        try package(folder: folder)
    } catch {
        print("Failed with error: \(error)")
        exit(1)
    }
}

main()
