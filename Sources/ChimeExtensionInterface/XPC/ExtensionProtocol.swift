import Foundation

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

/// Root protocol that all Chime extensions conform to.
public protocol ExtensionProtocol: AnyObject {

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
