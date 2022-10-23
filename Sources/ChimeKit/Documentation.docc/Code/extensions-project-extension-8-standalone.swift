import Foundation
import ChimeKit
import ProcessServiceContainer
import ChimeSwift

@main
final class SwiftStandaloneExtension: ChimeExtension {
    private var chimeExt: SwiftExtension?

    required init() {
        ServiceContainer.bootstrap()
    }

    func acceptHostConnection(_ host: HostProtocol) throws {
        self.chimeExt = SwiftExtension(host: host, processServiceHostName: ServiceContainer.name)
    }
}

extension SwiftStandaloneExtension {
    func didOpenProject(with context: ProjectContext) async throws {
        try await chimeExt?.didOpenProject(with: context)
    }

    func willCloseProject(with context: ProjectContext) async throws {
        try await chimeExt?.willCloseProject(with: context)
    }

    func didOpenDocument(with context: DocumentContext) async throws -> URL? {
        return try await chimeExt?.didOpenDocument(with: context)
    }

    func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
        try await chimeExt?.didChangeDocumentContext(from: oldContext, to: newContext)
    }

    func willCloseDocument(with context: DocumentContext) async throws {
        try await chimeExt?.willCloseDocument(with: context)
    }

    func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return try await chimeExt?.documentService(for: context)
    }

    func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
        return try await chimeExt?.symbolService(for: context)
    }
}
