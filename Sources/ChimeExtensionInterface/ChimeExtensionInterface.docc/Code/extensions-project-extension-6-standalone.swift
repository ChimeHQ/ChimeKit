import Foundation
import ChimeKit

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private var chimeExt: SwiftExtension?

    required init() {
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
        self.chimeExt = SwiftExtension(host: host)
    }
}

extension SwiftStandaloneExtension {
    func didOpenProject(with context: ProjectContext) async throws {
    }

    func willCloseProject(with context: ProjectContext) async throws {
    }

    func didOpenDocument(with context: DocumentContext) async throws -> URL? {
    }

    func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
    }

    func willCloseDocument(with context: DocumentContext) async throws {
    }

    func documentService(for context: DocumentContext) async throws -> DocumentService? {
    }

    func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
    }
}
