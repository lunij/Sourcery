import Foundation

public struct SourceryVersion {
    public let value: String
    public static let current = SourceryVersion(value: inUnitTests ? "Major.Minor.Patch" : "2.0.2")
}

public var inUnitTests = NSClassFromString("XCTest") != nil
