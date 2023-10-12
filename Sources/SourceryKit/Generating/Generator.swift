import Foundation
import SourceryRuntime

public enum Generator {
    public static func generate(_ parserResult: FileParserResult?, types: Types, functions: [SourceryMethod], template: Template, arguments: [String: NSObject] = [:]) throws -> String {
        Log.verbose("Rendering template \(template.sourcePath)")
        return try template.render(TemplateContext(parserResult: parserResult, types: types, functions: functions, arguments: arguments))
    }
}
