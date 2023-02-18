import Foundation

typealias XPCHandler = (Error?) -> Void
typealias XPCValueHandler<T> = (T?, Error?) -> Void
typealias XPCArray<T> = Data

typealias XPCTextChange = Data
typealias XPCTextRange = Data
typealias XPCTextTarget = Data
typealias XPCTextContent = Data
typealias XPCCombinedTextPosition = Data
typealias XPCCombinedTextRange = Data

typealias XPCProjectContext = Data
typealias XPCDocumentContext = Data
typealias XPCDocumentConfiguration = Data
typealias XPCDocumentServiceConfiguration = Data
typealias XPCExtensionConfiguration = Data

typealias XPCProjectSymbolsContext = Data
typealias XPCSemanticDetails = Data
typealias XPCDefinitionLocation = Data
typealias XPCCompletionTrigger = Data
typealias XPCToken = Data
typealias XPCDiagnostic = Data
typealias XPCSymbol = Data

/// Extension XPC API
@objc protocol ExtensionXPCProtocol {
	func configuration(completionHandler: @escaping XPCValueHandler<XPCExtensionConfiguration>)

    // ApplicationService
    func didOpenProject(with xpcContext: XPCProjectContext, bookmarkData: [Data])
    func willCloseProject(with xpcContext: XPCProjectContext)

    func didOpenDocument(with xpcContext: XPCDocumentContext, bookmarkData: [Data], completionHandler: @escaping XPCValueHandler<URL>)
    func didChangeDocumentContext(from xpcOldContext: XPCDocumentContext, to xpcNewContext: XPCDocumentContext, completionHandler: @escaping XPCHandler)
    func willCloseDocument(with xpcContext: XPCDocumentContext)

    // ExtensionDocumentService
    func willApplyChange(with xpcContext: XPCDocumentContext, xpcChange: XPCTextChange)
    func didApplyChange(with xpcContext: XPCDocumentContext, xpcChange: XPCTextChange)
    func willSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler)
    func didSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler)

    // CompletionService
    func completions(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, xpcTrigger: XPCCompletionTrigger, completionHandler: @escaping XPCValueHandler<Data>)
    
    // FormattingService
    func formatting(for xpcContext: XPCDocumentContext, for xpcRanges: XPCArray<XPCCombinedTextRange>, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>)
    func organizeImports(for xpcContext: XPCDocumentContext, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>)

    // DiagnosticsService

    // SemanticDetailsService
    func semanticDetails(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCSemanticDetails>)

    // DefinitionService
    func findDefinition(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCArray<XPCDefinitionLocation>>)

    // TokenService
    func tokens(for xpcContext: XPCDocumentContext, in xpcRange: XPCCombinedTextRange, completionHandler: @escaping XPCValueHandler<XPCArray<XPCToken>>)

    // SymbolQueryService
    func symbols(forProject xpcContext: XPCProjectContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>)
    func symbols(forDocument xpcContext: XPCDocumentContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>)
}

/// Host XPC API
@objc protocol HostXPCProtocol {
    func textContent(for id: UUID, reply: @escaping (String?, Int, Error?) -> Void)
    func textContent(for id: UUID, xpcRange: XPCTextRange, reply: @escaping XPCValueHandler<XPCTextContent>)
    func textBounds(for id: UUID, xpcRanges: Data, version: Int, reply: @escaping (Data?, Error?) -> Void)

    // DiagnosticsService
    func publishDiagnostics(_ xpcDiagnostics: XPCArray<XPCDiagnostic>, for documentURL: URL, version: NSNumber?)

    // TokenService
    func invalidateTokens(for documentId: UUID, in xpcTarget: XPCTextTarget)

	func extensionConfigurationChanged(to xpcConfiguration: XPCExtensionConfiguration)
    func documentServiceConfigurationChanged(for documentId: UUID, to xpcConfiguration: XPCDocumentServiceConfiguration)
}

/// Extension Scene XPC API
@objc protocol ExtensionSceneXPCProtocol {
    func setActiveContext(project xpcProjectContext: XPCProjectContext?, document xpcDocumentContext: XPCDocumentContext?, reply: @escaping (Error?) -> Void)
}

/// Scene Host XPC API
@objc protocol ExtensionSceneHostXPCProtocol {
    func textBounds(xpcRanges: XPCArray<XPCTextRange>, version: Int, reply: @escaping (XPCArray<NSRect>?, Error?) -> Void)
}
