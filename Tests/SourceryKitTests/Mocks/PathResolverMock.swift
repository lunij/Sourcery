@testable import SourceryKit

class PathResolverMock: PathResolving {
    enum Call: Equatable {
        case resolve([Path], [Path])
    }

    var calls: [Call] = []

    var resolveReturnValue: [Path]?
    var resolveReturnValues: [[Path]]?
    func resolve(includes: [Path], excludes: [Path]) -> [Path] {
        calls.append(.resolve(includes, excludes))
        if let resolveReturnValue { return resolveReturnValue }
        if let value = resolveReturnValues?.removeFirst() { return value }
        preconditionFailure("Mock needs to be configured")
    }
}
