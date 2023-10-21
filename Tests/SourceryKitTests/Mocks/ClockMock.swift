@testable import SourceryKit

final class ClockMock: TimeMeasuring {
    enum Call: Equatable {
        case measure
    }

    var calls: [Call] = []

    var measureReturnValue: Duration?
    func measure(_ work: () throws -> Void) rethrows -> Duration {
        calls.append(.measure)
        try work()
        if let measureReturnValue { return measureReturnValue }
        preconditionFailure("Mock needs to be configured")
    }
}
