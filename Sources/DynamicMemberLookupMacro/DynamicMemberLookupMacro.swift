import SwiftSyntax
import SwiftSyntaxMacros

public enum DynamicMemberLookupMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let variableNames = declaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .flatMap { $0.bindings.map(\.pattern.description) }

        let generatedCases = variableNames.map { name in
            SwitchCaseListSyntax.Element.switchCase(.init(
                label: .case(.init(caseItems: [
                    .init(pattern: ExpressionPatternSyntax(expression: StringLiteralExprSyntax(
                        openingQuote: .stringQuoteToken(),
                        segments: [
                            .stringSegment(.init(content: .stringSegment(name)))
                        ],
                        closingQuote: .stringQuoteToken()
                    )))
                ])),
                statements: [
                    CodeBlockItemSyntax(item: .expr(.init(DeclReferenceExprSyntax(baseName: .identifier(name)))))
                ]
            ))
        }

        return [
            DeclSyntax(
                SubscriptDeclSyntax(
                    modifiers: [
                        DeclModifierSyntax(name: "public")
                    ],
                    subscriptKeyword: .keyword(.subscript),
                    parameterClause: FunctionParameterClauseSyntax(parameters: [
                        FunctionParameterSyntax(
                            firstName: .identifier("dynamicMember"),
                            secondName: .identifier("member"),
                            type: IdentifierTypeSyntax(name: .identifier("String"))
                        )
                    ]),
                    returnClause: ReturnClauseSyntax(
                        type: OptionalTypeSyntax(wrappedType: IdentifierTypeSyntax(name: .keyword(.Any)))
                    ),
                    accessorBlock: AccessorBlockSyntax(accessors: .getter([
                        CodeBlockItemSyntax(item: .stmt(.init(
                            ExpressionStmtSyntax(expression: SwitchExprSyntax(
                                subject: DeclReferenceExprSyntax(baseName: .identifier("member")),
                                cases: generatedCases + [
                                    .switchCase(.init(
                                        label: .default(.init()),
                                        statements: [
                                            CodeBlockItemSyntax(item: .expr(.init(NilLiteralExprSyntax())))
                                        ]
                                    ))
                                ]
                            ))
                        )))
                    ]))
                )
            )
        ]
    }
}
