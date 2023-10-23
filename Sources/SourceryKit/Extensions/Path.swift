import PathKit

extension Path {
    var generatedFileName: String {
        "\(lastComponentWithoutExtension).generated.swift"
    }

    func appending(_ path: String) -> Path {
        self + Path(path)
    }
}

// MARK: - FileWritable

protocol FileWritable {
    func write(_ string: String, encoding: String.Encoding) throws
    func writeIfChanged(_ newContent: String) throws
}

extension FileWritable {
    func write(_ string: String) throws {
        try write(string, encoding: .utf8)
    }
}

extension Path: FileWritable {
    func writeIfChanged(_ newContent: String) throws {
        guard exists else {
            return try write(newContent)
        }

        let currentContent = try read(.utf8)
        if currentContent != newContent {
            try write(newContent)
        }
    }
}
