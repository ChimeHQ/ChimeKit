import Foundation

import ChimeExtensionInterface
import JSONRPC
#if os(macOS)
import ProcessEnv
import LanguageServerProtocol

extension DataChannel {
	@available(macOS 12.0, *)
	@MainActor
	static func hostedProcessChannel(
		host: HostProtocol,
		parameters: Process.ExecutionParameters,
		runInUserShell: Bool,
		terminationHandler: @escaping @Sendable () -> Void
	) async throws -> DataChannel {
		let process = try await host.launchProcess(with: parameters, inUserShell: runInUserShell)

		let (stream, continuation) = DataSequence.makeStream()

		let dataStream = process.stdoutHandle.dataStream

		Task {
			for try await data in dataStream {
				continuation.yield(data)
			}

			continuation.finish()
		}

		Task {
			for try await line in process.stderrHandle.bytes.lines {
				print("stderr: \(line)")
			}
		}

		let stdin = process.stdinHandle

		process.terminationHandler = {
			continuation.finish()
			terminationHandler()
		}

		let handler: DataChannel.WriteHandler = {
			_ = process

			try stdin.write(contentsOf: $0)
		}

		return DataChannel(writeHandler: handler,
						   dataSequence: stream)
	}
}
#endif
