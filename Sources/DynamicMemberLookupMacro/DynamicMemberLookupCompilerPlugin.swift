#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DynamicMemberLookupCompilerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DynamicMemberLookupMacro.self
    ]
}
#endif
