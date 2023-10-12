import Foundation
@testable import SourceryKit
@testable import SourceryRuntime

extension String {
    var withoutWhitespaces: String {
        return components(separatedBy: .whitespacesAndNewlines).joined(separator: "")
    }
}

extension Type {
    public func asUnknownException() -> Self {
        isUnknownExtension = true
        return self
    }
}
