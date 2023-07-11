import Foundation

import AsyncXPCConnection
import Queue

@MainActor
struct RemoteHost {
	typealias Service = QueuedRemoteXPCService<HostXPCProtocol, AsyncQueue>

    private let queuedService: Service

    public init(connection: NSXPCConnection) {
		let queue = AsyncQueue(attributes: [.concurrent, .publishErrors])

        self.queuedService = Service(queue: queue, connection: connection)
    }
}

extension RemoteHost: HostProtocol {
    public func textContent(for documentId: DocumentIdentity) async throws -> (String, Int) {
		try await queuedService.addValueErrorOperation(barrier: true) { service, handler in
			service.textContent(for: documentId) { value, version, error in
				let pair: (String, Int)? = value.map { ($0, version) }

				handler(pair, error)
			}
		}
    }

    public func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent {
        let xpcRange = try JSONEncoder().encode(range)

		return try await queuedService.addDecodingOperation(barrier: true) { service, handler in
			service.textContent(for: documentId, xpcRange: xpcRange, reply: handler)
		}
    }

    public func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [NSRect] {
        let xpcRanges = try JSONEncoder().encode(ranges)

		return try await queuedService.addDecodingOperation(barrier: true) { service, handler in
			service.textBounds(for: documentId, xpcRanges: xpcRanges, version: version, reply: handler)
		}
    }

    public func publishDiagnostics(_ diagnostics: [Diagnostic], for documentURL: URL, version: Int?) {
		queuedService.addOperation { service in
			let xpcDiagnostics = try JSONEncoder().encode(diagnostics)
			let xpcVersion = version.flatMap({ NSNumber(integerLiteral: $0) })

			service.publishDiagnostics(xpcDiagnostics, for: documentURL, version: xpcVersion)
		}
    }

    public func invalidateTokens(for documentId: UUID, in target: TextTarget) {
		queuedService.addOperation { service in
			let xpcTarget = try JSONEncoder().encode(target)

			service.invalidateTokens(for: documentId, in: xpcTarget)
		}
    }

	public func serviceConfigurationChanged(for documentId: DocumentIdentity, to configuration: ServiceConfiguration) {
		queuedService.addOperation(barrier: true) { service in
			let xpcConfig = try JSONEncoder().encode(configuration)

			service.serviceConfigurationChanged(for: documentId, to: xpcConfig)
		}
	}
}
