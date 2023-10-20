import Foundation
import SourceryRuntime

extension StencilTemplate: Template {
    public func render(_ context: TemplateContext) throws -> String {
        do {
            return try self.render(context.stencilContext)
        } catch {
            throw Error.renderingFailed(sourcePath: sourcePath, error: String(describing: error))
        }
    }
}
