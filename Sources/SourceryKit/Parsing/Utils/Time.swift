import Foundation

/// Returns current timestamp interval
public func currentTimestamp() -> TimeInterval {
    CFAbsoluteTimeGetCurrent()
}
