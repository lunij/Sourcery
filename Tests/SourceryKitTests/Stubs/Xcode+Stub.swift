@testable import SourceryKit

extension Xcode {
    static func stub(
        project: Path = "fakeProjectPath",
        targets: [String] = [],
        group: String? = nil
    ) -> Self {
        .init(project: project, targets: targets, group: group)
    }
}
