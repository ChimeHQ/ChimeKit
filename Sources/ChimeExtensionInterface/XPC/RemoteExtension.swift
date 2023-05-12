import Foundation

import ConcurrencyPlus

@MainActor
public final class RemoteExtension {
    private let connection: NSXPCConnection
    private var docServices: [DocumentIdentity: RemoteDocumentService]

    public init(connection: NSXPCConnection) {
        self.connection = connection
        self.docServices = [:]

        precondition(connection.remoteObjectInterface == nil)
        connection.remoteObjectInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
    }

    private func withContinuation<T>(function: String = #function, _ body: (ExtensionXPCProtocol, CheckedContinuation<T, Error>) -> Void) async throws -> T {
        return try await connection.withContinuation(body)
    }

    private func withService(function: String = #function, _ body: @Sendable (ExtensionXPCProtocol) -> Void) async throws {
        try await connection.withService(body)
    }
}

extension RemoteExtension: ExtensionProtocol {
	public var configuration: ExtensionConfiguration {
		get async throws {
			return try await withContinuation({ service, continuation in
				service.configuration(completionHandler: continuation.resumingHandler)
			})
		}
	}

    public func didOpenProject(with context: ProjectContext) async throws {
        let bookmarks: [Data] = [
            try context.url.bookmarkData(),
        ]

        let xpcContext = try JSONEncoder().encode(context)

		try await withService({ remote in
			remote.didOpenProject(with: xpcContext, bookmarkData: bookmarks)
		})
    }

    public func willCloseProject(with context: ProjectContext) async throws {
        let xpcContext = try JSONEncoder().encode(context)

		try await withService({ service in
			service.willCloseProject(with: xpcContext)
		})
    }

    public func didOpenDocument(with context: DocumentContext) async throws -> URL? {
        let xpcContext = try JSONEncoder().encode(context)

        let bookmarks: [Data] = [
            try context.url?.bookmarkData(),
        ].compactMap({ $0 })

		return try await withContinuation({ service, continuation in
			service.didOpenDocument(with: xpcContext, bookmarkData: bookmarks, completionHandler: { url, error in
				// have to special-case this because of the allowed optional
				switch (url, error) {
				case (let url, nil):
					continuation.resume(returning: url)
				case (_, let error?):
					continuation.resume(throwing: error)
				}
			})
		})
    }

    public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
        precondition(oldContext.id == newContext.id)

        let xpcOldContext = try JSONEncoder().encode(oldContext)
        let xpcNewContext = try JSONEncoder().encode(newContext)

		return try await withContinuation({ service, continuation in
			service.didChangeDocumentContext(from: xpcOldContext, to: xpcNewContext, completionHandler: continuation.resumingHandler)
		})
    }

    public func willCloseDocument(with context: DocumentContext) async throws {
        let xpcContext = try JSONEncoder().encode(context)

		try await withService { service in
			service.willCloseDocument(with: xpcContext)
		}
    }

    public func documentService(for context: DocumentContext) async throws -> DocumentService? {
		if let service = self.docServices[context.id] {
			return service
		}

		let service = RemoteDocumentService(connection: connection, context: context)

		docServices[context.id] = service

		return service
    }

    public func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
		return RemoteProjectService(connection: connection, context: context)
    }
}
