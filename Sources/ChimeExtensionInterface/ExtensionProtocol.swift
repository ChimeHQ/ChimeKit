import Foundation

public enum ChimeExtensionError: Error {
	case noHostConnection
	case unsupported
	case processNotFound(UUID)
}

/// Provides behaviors and functionality scoped to a specific document.
///
/// A significant portion of the functionality within the extension interface is implicitly scoped
/// to a particular document context, via a `DocumentService`. Chime can request a new `DocumentService`
/// from all extensions via ``ApplicationService.documentService(for:)`` after changes have been
/// processed.
///
/// - Important: The **type** of a document can change. If your extension only operates on certain
/// kinds of documents, be sure to pay attention the ``DocumentContext/uti`` property.
public protocol DocumentService {
	associatedtype TokenServiceType: TokenService
	associatedtype CompletionServiceType: CompletionService
	associatedtype FormattingServiceType: FormattingService
	associatedtype SemanticDetailsServiceType: SemanticDetailsService
	associatedtype DefinitionServiceType: DefinitionService
	associatedtype SymbolQueryServiceType: SymbolQueryService


	@MainActor
    func willApplyChange(_ change: CombinedTextChange) throws
	@MainActor
    func didApplyChange(_ change: CombinedTextChange) throws
	@MainActor
    func willSave() throws
	@MainActor
    func didSave() throws

	@MainActor
    var completionService: CompletionServiceType? { get throws }
	@MainActor
    var formattingService: FormattingServiceType? { get throws }
	@MainActor
    var semanticDetailsService: SemanticDetailsServiceType? { get throws }
	@MainActor
    var defintionService: DefinitionServiceType? { get throws }
	@MainActor
    var tokenService: TokenServiceType? { get throws }
	@MainActor
    var symbolService: SymbolQueryServiceType? { get throws }
}

/// Used to interface with the Chime application.
///
/// Chime manages the association of documents and projects. However, it has to respect platform
/// conventions and user interaction. This means that sometimes the relationship between document
/// and project can be unintuitive.
///
/// - Important: Do not make any assumptions about open/close order. A document may be opened
/// **before** a project, and only associated later.
public protocol ApplicationService {
	associatedtype SymbolQueryServiceType: SymbolQueryService
	associatedtype DocumentServiceType: DocumentService

	/// Called when a project/directory is opened by the editor.
	@MainActor
	func didOpenProject(with context: ProjectContext) throws
	@MainActor
	func willCloseProject(with context: ProjectContext) throws

	@MainActor
	func didOpenDocument(with context: DocumentContext) throws
	@MainActor
	func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws
	@MainActor
	func willCloseDocument(with context: DocumentContext) throws

	@MainActor
	func documentService(for context: DocumentContext) throws -> DocumentServiceType?

	@MainActor
	func symbolService(for context: ProjectContext) throws -> SymbolQueryServiceType?
}

/// Root functionality used to interface with the Chime extension system.
public protocol ExtensionProtocol: AnyObject {
	associatedtype AppService: ApplicationService

	/// Static configuration used by the host.
	@MainActor
	var configuration: ExtensionConfiguration { get throws }

	/// The core service that interfaces with the application.
	@MainActor
	var applicationService: AppService { get throws }
}
