import Foundation
import PathKit
import SourceryRuntime

public protocol FileParserType {
    var path: String? { get }
    var modifiedDate: Date? { get }

    /// Creates parser for a given contents and path.
    /// - Throws: parsing errors.
    init(contents: String, forceParse: [String], parseDocumentation: Bool, path: Path?, module: String?) throws

    /// Parses given file context.
    ///
    /// - Returns: All types we could find.
    func parse() throws -> FileParserResult
}
