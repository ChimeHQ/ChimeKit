import Foundation
import OSLog

import AsyncXPCConnection
import Queue

@MainActor
final class RemoteHost {
	typealias Service = QueuedRemoteXPCService<HostXPCProtocol, AsyncQueue>

    private let queuedService: Service
	private var runningProcesses = [UUID: LaunchedProcess]()
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "RemoteHost")

    public init(connection: NSXPCConnection) {
		let queue = AsyncQueue(attributes: [.concurrent, .publishErrors])

		precondition(connection.remoteObjectInterface == nil)
		connection.remoteObjectInterface = NSXPCInterface(with: HostXPCProtocol.self)

        self.queuedService = Service(queue: queue, connection: connection)

		Task { [logger] in
			for await error in queue.errorSequence {
				logger.error("queue error: \(error, privacy: .public)")
			}
		}
    }
}

extension RemoteHost: HostProtocol {
    public func textContent(for documentId: DocumentIdentity) async throws -> (String, Int) {
		let value = try await queuedService.addValueErrorOperation(barrier: true) { service, handler in
			service.textContent(for: documentId) { value, version, error in
				let pair: (String, Int)? = value.map { ($0, version) }

				handler(pair, error)
			}
		}

		return value
    }

    public func textContent(for documentId: DocumentIdentity, in range: TextRange) async throws -> CombinedTextContent {
        let xpcRange = try JSONEncoder().encode(range)

		return try await queuedService.addDecodingOperation(barrier: true) { service, handler in
			service.textContent(for: documentId, xpcRange: xpcRange, reply: handler)
		}
    }

    public func textBounds(for documentId: DocumentIdentity, in ranges: [TextRange], version: Int) async throws -> [CGRect] {
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

	public func launchProcess(with parameters: Process.ExecutionParameters, inUserShell: Bool) async throws -> LaunchedProcess {
		let process = try await queuedService.addValueErrorOperation { service, handler in
			let xpcParams = try! JSONEncoder().encode(parameters)

			service.launchProcess(with: xpcParams, inUserShell: inUserShell) { id, stdin, stdout, stderr, error in
				let process = LaunchedProcess(id: id, stdinHandle: stdin, stdoutHandle: stdout, stderrHandle: stderr)

				handler(process, error)
			}
		}

		// store this so we can relay the termination later on
		self.runningProcesses[process.id] = process

		return process
	}

	func captureUserEnvironment() async throws -> [String : String] {
		try await queuedService.addValueErrorOperation(barrier: true) { service, handler in
			service.captureUserEnvironment(reply: handler)
		}
	}
}

extension RemoteHost {
	func handleProcessTerminated(with id: UUID) throws {
		guard let process = runningProcesses[id] else {
			throw ChimeExtensionError.processNotFound(id)
		}

		process.terminationHandler()

		runningProcesses[id] = nil
	}
}
