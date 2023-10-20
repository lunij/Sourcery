// Generated using Sourcery

class PathResolvingMock: PathResolving {




    // MARK: - resolve

    var resolveIncludesExcludesCallsCount = 0
    var resolveIncludesExcludesCalled: Bool {
        return resolveIncludesExcludesCallsCount > 0
    }
    var resolveIncludesExcludesReceivedArguments: (includes: [Path], excludes: [Path])?
    var resolveIncludesExcludesReceivedInvocations: [(includes: [Path], excludes: [Path])] = []
    var resolveIncludesExcludesReturnValue: [Path]!
    var resolveIncludesExcludesClosure: (([Path], [Path]) -> [Path])?

    func resolve(includes: [Path], excludes: [Path]) -> [Path] {
        resolveIncludesExcludesCallsCount += 1
        resolveIncludesExcludesReceivedArguments = (includes: includes, excludes: excludes)
        resolveIncludesExcludesReceivedInvocations.append((includes: includes, excludes: excludes))
        if let resolveIncludesExcludesClosure = resolveIncludesExcludesClosure {
            return resolveIncludesExcludesClosure(includes, excludes)
        } else {
            return resolveIncludesExcludesReturnValue
        }
    }

}
