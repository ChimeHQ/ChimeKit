import Foundation

public final class LaunchedProcess: @unchecked Sendable {
	public typealias TerminationHandler = @Sendable () -> Void

	private let lock = NSLock()
	private var handler: TerminationHandler

	public let id: UUID
	public let stdinHandle: FileHandle
	public let stdoutHandle: FileHandle
	public let stderrHandle: FileHandle

	public init(id: UUID, stdinHandle: FileHandle, stdoutHandle: FileHandle, stderrHandle: FileHandle) {
		self.id = id
		self.stdinHandle = stdinHandle
		self.stdoutHandle = stdoutHandle
		self.stderrHandle = stderrHandle
		self.handler = {}
	}

	convenience init?(id: UUID?, stdinHandle: FileHandle?, stdoutHandle: FileHandle?, stderrHandle: FileHandle?) {
		guard
			let id,
			let stdinHandle,
			let stdoutHandle,
			let stderrHandle
		else {
			return nil
		}

		self.init(id: id, stdinHandle: stdinHandle, stdoutHandle: stdoutHandle, stderrHandle: stderrHandle)
	}

	public var terminationHandler: TerminationHandler {
		get {
			lock.withLock {
				return handler
			}
		}
		set {
			lock.withLock {
				self.handler = newValue
			}
		}
	}
}

extension LaunchedProcess {
	public func readStdout() async throws -> Data {
		try stdoutHandle.readToEnd() ?? Data()
	}
}
