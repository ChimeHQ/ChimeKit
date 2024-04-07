import Foundation

typealias XPCHandler = @Sendable (Error?) -> Void
typealias XPCValueHandler<T> = @Sendable (T?, Error?) -> Void
typealias XPCArray<T> = Data

typealias XPCTextChange = Data
typealias XPCTextRange = Data
typealias XPCTextTarget = Data
typealias XPCTextContent = Data
typealias XPCCombinedTextPosition = Data
typealias XPCCombinedTextRange = Data

typealias XPCProjectContext = Data
typealias XPCDocumentContext = Data
typealias XPCServiceConfiguration = Data
typealias XPCExtensionConfiguration = Data

typealias XPCProjectSymbolsContext = Data
typealias XPCSemanticDetails = Data
typealias XPCDefinitionLocation = Data
typealias XPCCompletionTrigger = Data
typealias XPCToken = Data
typealias XPCDiagnostic = Data
typealias XPCSymbol = Data

typealias XPCExecutionParamters = Data

/// Extension XPC API
@objc protocol ExtensionXPCProtocol {
	@MainActor
	func configuration(completionHandler: @escaping XPCValueHandler<XPCExtensionConfiguration>)

    // ApplicationService
	@MainActor
    func didOpenProject(with xpcContext: XPCProjectContext, bookmarkData: [Data])
	@MainActor
    func willCloseProject(with xpcContext: XPCProjectContext)

	@MainActor
    func didOpenDocument(with xpcContext: XPCDocumentContext, bookmarkData: [Data])
	@MainActor
    func didChangeDocumentContext(from xpcOldContext: XPCDocumentContext, to xpcNewContext: XPCDocumentContext)
	@MainActor
    func willCloseDocument(with xpcContext: XPCDocumentContext)

	@MainActor
	func launchedProcessTerminated(with id: UUID)

    // ExtensionDocumentService
	@MainActor
    func willApplyChange(with xpcContext: XPCDocumentContext, xpcChange: XPCTextChange)
	@MainActor
    func didApplyChange(with xpcContext: XPCDocumentContext, xpcChange: XPCTextChange)
	@MainActor
    func willSave(with xpcContext: XPCDocumentContext, completionHandler: @escaping XPCHandler)
	@MainActor
    func didSave(with xpcContext: XPCDocumentContext)

    // CompletionService
	@MainActor
    func completions(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, xpcTrigger: XPCCompletionTrigger, completionHandler: @escaping XPCValueHandler<Data>)
    
    // FormattingService
	@MainActor
    func formatting(for xpcContext: XPCDocumentContext, for xpcRanges: XPCArray<XPCCombinedTextRange>, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>)
	@MainActor
    func organizeImports(for xpcContext: XPCDocumentContext, completionHandler: @escaping XPCValueHandler<XPCArray<XPCTextChange>>)

    // DiagnosticsService

    // SemanticDetailsService
	@MainActor
    func semanticDetails(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCSemanticDetails>)

    // DefinitionService
	@MainActor
    func findDefinition(for xpcContext: XPCDocumentContext, at xpcPosition: XPCCombinedTextPosition, completionHandler: @escaping XPCValueHandler<XPCArray<XPCDefinitionLocation>>)

    // TokenService
	@MainActor
    func tokens(for xpcContext: XPCDocumentContext, in xpcRange: XPCCombinedTextRange, completionHandler: @escaping XPCValueHandler<XPCArray<XPCToken>>)

    // SymbolQueryService
	@MainActor
    func symbols(forProject xpcContext: XPCProjectContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>)
	@MainActor
    func symbols(forDocument xpcContext: XPCDocumentContext, matching query: String, completionHandler: @escaping XPCValueHandler<XPCArray<XPCSymbol>>)
}

/// Host XPC API
@objc protocol HostXPCProtocol {
	@MainActor
    func textContent(for id: UUID, reply: @escaping (String?, Int, Error?) -> Void)
	@MainActor
    func textContent(for id: UUID, xpcRange: XPCTextRange, reply: @escaping XPCValueHandler<XPCTextContent>)
	@MainActor
    func textBounds(for id: UUID, xpcRanges: Data, version: Int, reply: @escaping XPCValueHandler<Data>)

    // DiagnosticsService
	@MainActor
    func publishDiagnostics(_ xpcDiagnostics: XPCArray<XPCDiagnostic>, for documentURL: URL, version: NSNumber?)

    // TokenService
	@MainActor
    func invalidateTokens(for documentId: UUID, in xpcTarget: XPCTextTarget)

	@MainActor
	func serviceConfigurationChanged(for documentId: UUID, to xpcConfiguration: XPCServiceConfiguration)

	// ProcessService
	@MainActor
	func launchProcess(with xpcParameters: XPCExecutionParamters, inUserShell: Bool, reply: @escaping @Sendable (UUID?, FileHandle?, FileHandle?, FileHandle?, Error?) -> Void)
	@MainActor
	func captureUserEnvironment(reply: @escaping XPCValueHandler<[String: String]>)
}

/// Extension Scene XPC API
@objc protocol ExtensionSceneXPCProtocol {
	@MainActor
    func setActiveContext(project xpcProjectContext: XPCProjectContext?, document xpcDocumentContext: XPCDocumentContext?, reply: @escaping (Error?) -> Void)
}

/// Scene Host XPC API
@objc protocol ExtensionSceneHostXPCProtocol {
	@MainActor
	func textBounds(xpcRanges: XPCArray<XPCTextRange>, version: Int, reply: @escaping (XPCArray<CGRect>?, Error?) -> Void)
}
