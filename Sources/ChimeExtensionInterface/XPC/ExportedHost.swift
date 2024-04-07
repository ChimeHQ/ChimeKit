import Foundation

#if canImport(ProcessEnv)
import ProcessEnv
#endif

/// Export a `HostProtocol`-conforming type over XPC.
///
/// This type is used internally by Chime's extension system, and should not be used by
/// 3rd-parties.
@MainActor
public final class ExportedHost<Host: HostProtocol>: HostXPCProtocol {
    let bridgedObject: Host
	private let queuedRelay: QueuedRelay
	// I'm actually not 100% sure this need to be weak
	private weak var remoteExtension: RemoteExtension?

	init(_ object: Host, remoteExtension: RemoteExtension) {
        self.bridgedObject = object
		self.remoteExtension = remoteExtension
		self.queuedRelay = QueuedRelay(attributes: [.concurrent])
    }

    func textContent(for id: UUID, reply: @escaping (String?, Int, Error?) -> Void) {
		queuedRelay.addOperation {
			do {
				let pair = try await self.bridgedObject.textContent(for: id)

				reply(pair.0, pair.1, nil)
			} catch {
				reply(nil, 0, error)
				throw error
			}
		}
    }

    func textContent(for id: UUID, xpcRange: XPCTextRange, reply: @escaping XPCValueHandler<XPCTextContent>) {
		queuedRelay.addEncodingOperation(with: reply) {
			let range = try JSONDecoder().decode(TextRange.self, from: xpcRange)
			return try await self.bridgedObject.textContent(for: id, in: range)
		}
    }

    func textBounds(for id: UUID, xpcRanges: Data, version: Int, reply: @escaping XPCValueHandler<Data>) {
		queuedRelay.addEncodingOperation(with: reply) {
			let ranges = try JSONDecoder().decode([TextRange].self, from: xpcRanges)

			return try await self.bridgedObject.textBounds(for: id, in: ranges, version: version)
		}
    }

    func publishDiagnostics(_ xpcDiagnostics: XPCArray<XPCDiagnostic>, for documentURL: URL, version: NSNumber?) {
		queuedRelay.addOperation {
			let diagnostics = try JSONDecoder().decode([Diagnostic].self, from: xpcDiagnostics)

			self.bridgedObject.publishDiagnostics(diagnostics, for: documentURL, version: version?.intValue)
		}
    }

    func invalidateTokens(for documentId: UUID, in xpcTarget: XPCTextTarget) {
		queuedRelay.addOperation {
			let target = try JSONDecoder().decode(TextTarget.self, from: xpcTarget)

			self.bridgedObject.invalidateTokens(for: documentId, in: target)
		}
    }

	func serviceConfigurationChanged(for documentId: UUID, to xpcConfiguration: XPCServiceConfiguration) {
		queuedRelay.addOperation(barrier: true) {
			let config = try JSONDecoder().decode(ServiceConfiguration.self, from: xpcConfiguration)

			self.bridgedObject.serviceConfigurationChanged(for: documentId, to: config)
		}
	}

	func launchProcess(with xpcParameters: XPCExecutionParamters, inUserShell: Bool, reply: @escaping @Sendable (UUID?, FileHandle?, FileHandle?, FileHandle?, Error?) -> Void) {
		queuedRelay.addOperation(barrier: true) {
			let params = try JSONDecoder().decode(Process.ExecutionParameters.self, from: xpcParameters)

			do {
				let process = try await self.bridgedObject.launchProcess(with: params, inUserShell: inUserShell)

				self.setupTerminationMonitoring(for: process)

				reply(process.id, process.stdinHandle, process.stdoutHandle, process.stderrHandle, nil)
			} catch {
				reply(nil, nil, nil, nil, error)
				throw error
			}
		}
	}

	func captureUserEnvironment(reply: @escaping XPCValueHandler<[String : String]>) {
		queuedRelay.addValueErrorOperation(with: reply) {
			try await self.bridgedObject.captureUserEnvironment()
		}
	}
}

extension ExportedHost {
	private nonisolated func nonisolatedHandleTermination(of id: UUID) {
		Task {
			await handleTermination(of: id)
		}
	}

	private func handleTermination(of id: UUID) {
		remoteExtension?.launchedProcessTerminated(with: id)
	}

	private func setupTerminationMonitoring(for process: LaunchedProcess) {
		let id = process.id

		process.terminationHandler = { [weak self] in self?.nonisolatedHandleTermination(of: id) }
	}
}
