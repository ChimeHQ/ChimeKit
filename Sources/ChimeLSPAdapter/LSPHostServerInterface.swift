import Foundation

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
		_ operation: @MainActor @escaping (Server, LSPTransformers, HostProtocol) async throws -> Void
	) {
		queue.addOperation {
			do {
				try await operation(server, transformers, host)
			} catch {
				print("need to relay error back to host: \(error)")
			}
		}
	}

	func enqueueBarrier(
		_ operation: @MainActor @escaping (Server, LSPTransformers, HostProtocol) async throws -> Void
	) {
		// should we cancel pending operations here?
		queue.addBarrierOperation {
			do {
				try await operation(server, transformers, host)
			} catch {
				print("need to relay error back to host: \(error)")
			}
		}
	}
}
