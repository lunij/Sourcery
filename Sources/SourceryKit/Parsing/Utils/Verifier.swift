import Foundation
import PathKit

public enum Verifier {
    // swiftlint:disable:next force_try
    private static let conflictRegex = try! NSRegularExpression(pattern: "^\\s+?(<<<<<|>>>>>)")

    public enum Result {
        case isCodeGenerated
        case containsConflictMarkers
        case approved
    }

    public static func canParse(
        content: String,
        path: Path,
        forceParse: [String] = []
    ) -> Result {
        guard !content.isEmpty else { return .approved }

        let shouldForceParse = forceParse.contains { name in
            path.hasExtension(as: name)
        }

        if content.hasPrefix(.generatedHeader), shouldForceParse == false {
            return .isCodeGenerated
        }

        if conflictRegex.numberOfMatches(in: content, options: .anchored, range: content.bridge().entireRange) > 0 {
            return .containsConflictMarkers
        }

        return .approved
    }
}
