import Foundation
import SourceryRuntime
import SourceryStencil

extension StencilTemplate: Template {
    public func render(_ context: TemplateContext) throws -> String {
        do {
            return try self.render(context.stencilContext)
        } catch {
            throw "\(sourcePath): \(error)"
        }
    }
}
