import Foundation

public enum ChimeExtensionError: Error {
	case noHostConnection
}

/// Provides behaviors and functionality scoped to a specific document.
///
/// A significant portion of the functionality within the extension interface is implicitly scoped
/// to a particular document context, via a `DocumentService`. Chime can request a new `DocumentService`
/// from all extensions via ``ExtensionProtocol/documentService(for:)-a5ry`` after changes have been
/// processed.
///
/// - Important: The **type** of a document can change. If your extension only operates on certain
/// kinds of documents, be sure to pay attention the ``DocumentContext/uti`` property.
public protocol DocumentService {
    func willApplyChange(_ change: CombinedTextChange) async throws
    func didApplyChange(_ change: CombinedTextChange) async throws
    func willSave() async throws
    func didSave() async throws

    var configuration: ServiceConfiguration { get async throws }

    var completionService: CompletionService? { get async throws }
    var formattingService: FormattingService? { get async throws }
    var semanticDetailsService: SemanticDetailsService? { get async throws }
    var defintionService: DefinitionService? { get async throws }
    var tokenService: TokenService? { get async throws }
    var symbolService: SymbolQueryService? { get async throws }
}

public extension DocumentService {
    func willApplyChange(_ change: CombinedTextChange) async throws {
    }

    func didApplyChange(_ change: CombinedTextChange) async throws {
    }

    func willSave() async throws {
    }

    func didSave() async throws {
    }

    var completionService: CompletionService? { get async throws { return nil } }
    var formattingService: FormattingService? { get async throws { return nil } }
    var semanticDetailsService: SemanticDetailsService? { get async throws { return nil } }
    var defintionService: DefinitionService? { get async throws { return nil } }
    var tokenService: TokenService? { get async throws { return nil } }
    var symbolService: SymbolQueryService? { get async throws { return nil } }

    var configuration: ServiceConfiguration {
        get async throws {
            return ServiceConfiguration()
        }
    }
}

/// Root functionality used to interface with the Chime application.
///
/// Chime manages the association of documents and projects. However, it has to respect platform
/// conventions and user interaction. This means that sometimes the relationship between document
/// and project can be unintuitive.
///
/// - Important: Do not make any assumptions about open/close order. A document may be opened
/// **before** a project, and only associated later.
public protocol ExtensionProtocol: AnyObject {
	/// Static configuration used by the host
	var configuration: ExtensionConfiguration { get async throws }

	/// Called when a project/directory is opened by the editor.
    func didOpenProject(with context: ProjectContext) async throws
    func willCloseProject(with context: ProjectContext) async throws

    func didOpenDocument(with context: DocumentContext) async throws -> URL?
    func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws
    func willCloseDocument(with context: DocumentContext) async throws

    func documentService(for context: DocumentContext) async throws -> DocumentService?

    func symbolService(for context: ProjectContext) async throws -> SymbolQueryService?
}

public extension ExtensionProtocol {
	var configuration: ExtensionConfiguration {
		get async throws {
			return ExtensionConfiguration()
		}
	}
	
    func didOpenProject(with context: ProjectContext) async throws {
    }

    func willCloseProject(with context: ProjectContext) async throws {
    }

    func didOpenDocument(with context: DocumentContext) async throws -> URL? {
        return nil
    }

    func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
    }

    func willCloseDocument(with context: DocumentContext) async throws {
    }

    func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return nil
    }

    func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
        return nil
    }
}
