import Foundation
import OSLog

import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol
import Queue

extension DocumentContext {
	var uri: DocumentUri {
		get throws {
			guard let url = url else {
				throw LSPServiceError.documentURLInvalid(self)
			}

			return url.absoluteString
		}
	}

	var textDocumentIdentifier: TextDocumentIdentifier {
		get throws {
			try TextDocumentIdentifier(uri: uri)
		}
	}
}

@MainActor
struct LSPHostServerInterface {
	typealias Server = LSPProjectService.Server

	let host: HostProtocol
	let server: Server
	private let queue: AsyncQueue
	let transformers: LSPTransformers

	init(host: HostProtocol, server: Server, queue: AsyncQueue, transformers: LSPTransformers) {
		self.host = host
		self.server = server
		self.queue = queue
		self.transformers = transformers
	}
}

extension LSPHostServerInterface {
	func operationValue<T: Sendable>(
		_ operation: @MainActor @escaping (Server, LSPTransformers, HostProtocol) async throws -> T
	) async throws -> T {
		let task = queue.addOperation {
			try await operation(server, transformers, host)
		}

		return try await task.value
	}

	func enqueue(
		barrier: Bool = false,
		_ operation: @MainActor @escaping (Server, LSPTransformers, HostProtocol) async throws -> Void
	) {
		// should we cancel pending operations here if this is a barrier?
		queue.addOperation(barrier: barrier) {
			try await operation(server, transformers, host)
		}
	}
}
