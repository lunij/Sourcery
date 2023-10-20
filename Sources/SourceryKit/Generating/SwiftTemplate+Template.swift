import Foundation
import SourceryRuntime

extension SwiftTemplate: Template {

    public func render(_ context: TemplateContext) throws -> String {
        return try self.render(context as Any)
    }

}
