import Foundation
import PathKit
@testable import SourceryKit
@testable import SourceryRuntime

extension Path {
    static func createTestDirectory(suffixed suffix: String) throws -> Path {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory.appending(path: "test-sourcery-\(suffix)")
        _ = try? fileManager.removeItem(at: url)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return Path(url.path)
    }
}

extension String {
    var withoutWhitespaces: String {
        components(separatedBy: .whitespacesAndNewlines).joined(separator: "")
    }
}

public extension Type {
    func asUnknownException() -> Self {
        isUnknownExtension = true
        return self
    }
}
