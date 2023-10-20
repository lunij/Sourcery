// Generated using Sourcery

class TimeMeasuringMock: TimeMeasuring {




    // MARK: - measure

    var measureCallsCount = 0
    var measureCalled: Bool {
        return measureCallsCount > 0
    }
    var measureReturnValue: Duration!
    var measureClosure: ((() throws -> Void) -> Duration)?

    func measure(_ work: () throws -> Void) -> Duration {
        measureCallsCount += 1
        if let measureClosure = measureClosure {
            return measureClosure(work)
        } else {
            return measureReturnValue
        }
    }

}
