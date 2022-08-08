import Foundation

import LanguageServerProtocol

extension LSPService {
    static let clientCapabilities: ClientCapabilities = {
        let workspaceEdit = WorkspaceClientCapabilityEdit(documentChanges: false,
                                                          resourceOperations: [],
                                                          failureHandling: .abort)
        let workspaceSymbol = WorkspaceSymbolClientCapabilities(dynamicRegistration: false,
                                                                symbolKind: SymbolKind.allCases,
                                                                tagSupport: SymbolTag.allCases,
                                                                resolveSupport: [])

        let workspaceCaps = ClientCapabilities.Workspace(applyEdit: false,
                                                        workspaceEdit: workspaceEdit,
                                                        didChangeConfiguration: GenericDynamicRegistration(dynamicRegistration: true),
                                                        didChangeWatchedFiles: GenericDynamicRegistration(dynamicRegistration: true),
                                                        symbol: workspaceSymbol,
                                                        executeCommand: GenericDynamicRegistration(dynamicRegistration: false),
                                                        workspaceFolders: false,
                                                        configuration: true,
                                                        semanticTokens: SemanticTokensWorkspaceClientCapabilities(refreshSupport: true))

        let syncCaps = TextDocumentSyncClientCapabilities(dynamicRegistration: false,
                                                          willSave: false,
                                                          willSaveWaitUntil: false,
                                                          didSave: true)

        let completionItemCaps = CompletionClientCapabilities.CompletionItem(snippetSupport: true,
                                                                             commitCharactersSupport: true,
                                                                             documentationFormat: [.plaintext],
                                                                             deprecatedSupport: true,
                                                                             preselectSupport: true,
                                                                             tagSupport: nil,
                                                                             insertReplaceSupport: false,
                                                                             resolveSupport: nil,
                                                                             insertTextModeSupport: nil,
                                                                             labelDetailsSupport: false)
        let completionCaps = CompletionClientCapabilities(dynamicRegistration: false,
                                                          completionItem: completionItemCaps,
                                                          completionItemKind: .all,
                                                          contextSupport: false,
                                                          insertTextMode: nil,
                                                          completionList: nil)

        let hoverCaps = HoverClientCapabilities(dynamicRegistration: false, contentFormat: [.plaintext])
        let diagnosticsCaps = PublishDiagnosticsClientCapabilities(relatedInformation: true, tagSupport: .all, versionSupport: true, codeDescriptionSupport: false, dataSupport: false)
        let definitionCaps = DefinitionClientCapabilities(dynamicRegistration: false, linkSupport: true)
        let formattingCaps = DocumentFormattingClientCapabilities(dynamicRegistration: false)
        let rangeFormattingCaps = DocumentRangeFormattingClientCapabilities(dynamicRegistration: false)
        let onTypeFormattingsCaps = DocumentOnTypeFormattingClientCapabilities(dynamicRegistration: false)

        let codeActionLiteralSupport = CodeActionClientCapabilities.CodeActionLiteralSupport(codeActionKind: [CodeActionKind.SourceOrganizeImports])
        let codeActionCaps = CodeActionClientCapabilities(dynamicRegistration: false,
                                                          codeActionLiteralSupport: codeActionLiteralSupport,
                                                          isPreferredSupport: false,
                                                          disabledSupport: false,
                                                          dataSupport: false,
                                                          resolveSupport: CodeActionClientCapabilities.ResolveSupport(properties: []),
                                                          honorsChangeAnnotations: false)

//        let supportedTokenTypes = SemanticTokenTypes.allCases.filter { type in
//            switch type {
//            case .string, .operator:
//                return false
//            default:
//                return true
//            }
//        }.map({ $0.rawValue })
        let supportedTokenTypes = SemanticTokenTypes.allStrings

        let semanticTokensCaps = SemanticTokensClientCapabilities(dynamicRegistration: true,
                                                                  requests: SemanticTokensClientCapabilities.Requests(range: true, delta: true),
                                                                  tokenTypes: supportedTokenTypes,
                                                                  tokenModifiers: SemanticTokenModifiers.allStrings,
                                                                  formats: [TokenFormat.Relative],
                                                                  overlappingTokenSupport: true,
                                                                  multilineTokenSupport: true)

        let textDocumentCaps = TextDocumentClientCapabilities(synchronization: syncCaps,
                                                              completion: completionCaps,
                                                              hover: hoverCaps,
                                                              definition: definitionCaps,
                                                              codeAction: codeActionCaps,
                                                              formatting: formattingCaps,
                                                              rangeFormatting: rangeFormattingCaps,
                                                              onTypeFormatting: onTypeFormattingsCaps,
                                                              publishDiagnostics: diagnosticsCaps,
                                                              semanticTokens: semanticTokensCaps)

        return ClientCapabilities(workspace: workspaceCaps, textDocument: textDocumentCaps, window: nil, general: nil, experimental: nil)
    }()
}
