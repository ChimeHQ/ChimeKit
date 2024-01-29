import Foundation

import AsyncXPCConnection
import Queue

extension AsyncQueue: AsyncQueuing {}

/// Maintains order of communcations across to a remote ExtensionProtocol object.
@MainActor
public final class RemoteExtension {
	typealias Service = QueuedRemoteXPCService<ExtensionXPCProtocol, AsyncQueue>
	public typealias ConnectionProvider = @MainActor () async throws -> NSXPCConnection
	private let queuedService: Service
    private var docServices = [DocumentIdentity: RemoteDocumentService]()
	private let queue = AsyncQueue(attributes: [.concurrent, .publishErrors])

	public init(connectionProvider: @escaping ConnectionProvider) {
		self.queuedService = Service(queue: queue, provider: {
			let conn = try await connectionProvider()

			if conn.remoteObjectInterface == nil {
				conn.remoteObjectInterface = NSXPCInterface(with: ExtensionXPCProtocol.self)
			}
			
			return conn
		})
    }

	public var errorSequence: AsyncQueue.ErrorSequence {
		queue.errorSequence
	}

	public var configuration: ExtensionConfiguration {
		get async throws {
			return try await queuedService.addDecodingOperation(barrier: true) { service, handler in
				service.configuration(completionHandler: handler)
			}
		}
	}

	public func launchedProcessTerminated(with id: UUID) {
		queuedService.addOperation(barrier: true) { service in
			service.launchedProcessTerminated(with: id)
		}
	}
}

extension RemoteExtension: ApplicationService {
	public func didOpenProject(with context: ProjectContext) throws {
		let bookmarks: [Data] = [
			try context.url.bookmarkData(),
		]

		let xpcContext = try JSONEncoder().encode(context)

		queuedService.addOperation(barrier: true) { service in
			service.didOpenProject(with: xpcContext, bookmarkData: bookmarks)
		}
	}

	public func willCloseProject(with context: ProjectContext) throws {
		let xpcContext = try JSONEncoder().encode(context)

		queuedService.addOperation(barrier: true) { service in
			service.willCloseProject(with: xpcContext)
		}
	}

	public func didOpenDocument(with context: DocumentContext) throws {
		let xpcContext = try JSONEncoder().encode(context)

		let bookmarks: [Data] = [
			try context.url?.bookmarkData(),
		].compactMap({ $0 })

		queuedService.addOperation(barrier: true) { service in
			service.didOpenDocument(with: xpcContext, bookmarkData: bookmarks)
		}
	}

	public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws {
		precondition(oldContext.id == newContext.id)

		let xpcOldContext = try JSONEncoder().encode(oldContext)
		let xpcNewContext = try JSONEncoder().encode(newContext)

		queuedService.addOperation(barrier: true) { service in
			service.didChangeDocumentContext(from: xpcOldContext, to: xpcNewContext)
		}
	}

	public func willCloseDocument(with context: DocumentContext) throws {
		let xpcContext = try JSONEncoder().encode(context)

		queuedService.addOperation(barrier: true) { service in
			service.willCloseDocument(with: xpcContext)
		}
	}

	public func documentService(for context: DocumentContext) throws -> (some DocumentService)? {
		if let service = self.docServices[context.id] {
			return service
		}

		let service = RemoteDocumentService(queuedService: queuedService, context: context)

		docServices[context.id] = service

		return service
	}

	public func symbolService(for context: ProjectContext) throws -> (some SymbolQueryService)? {
		return RemoteProjectService(queuedService: queuedService, context: context)
	}
}
