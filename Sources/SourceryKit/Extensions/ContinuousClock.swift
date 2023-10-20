// sourcery: AutoMockable
protocol TimeMeasuring {
    func measure(_ work: () throws -> Void) rethrows -> Duration
}

extension ContinuousClock: TimeMeasuring {}
