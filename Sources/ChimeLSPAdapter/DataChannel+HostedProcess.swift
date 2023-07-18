import Foundation

import ChimeExtensionInterface
import JSONRPC
import ProcessEnv
import LanguageServerProtocol

extension DataChannel {
	@available(macOS 12.0, *)
	@MainActor
	static func hostedProcessChannel(
		host: HostProtocol,
		parameters: Process.ExecutionParameters,
		terminationHandler: @escaping @Sendable () -> Void
	) async throws -> DataChannel {
		let process = try await host.launchProcess(with: parameters)

		let (stream, continuation) = DataSequence.makeStream()

		let dataStream = process.stdoutHandle.dataStream
		let byteStream = AsyncByteSequence(base: dataStream)
		let framedData = AsyncMessageFramingSequence(base: byteStream)

		Task {
			for try await data in framedData {
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

			let data = MessageFraming.frame($0)

			try stdin.write(contentsOf: data)
		}

		return DataChannel(writeHandler: handler,
						   dataSequence: stream)
	}
}
