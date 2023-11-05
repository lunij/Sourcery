import Foundation
import PathKit

/// Generic template that can be used for any of the Sourcery output variants
public protocol Template {
    /// Path to template
    var path: Path { get }

    /// Generate
    ///
    /// - Parameter types: List of types to generate.
    /// - Parameter arguments: List of template arguments.
    /// - Returns: Generated code.
    /// - Throws: `Throws` template errors
    func render(_ context: TemplateContext) throws -> String
}
