import Foundation

import JSONRPC
import ProcessEnv
import ProcessServiceClient

extension DataChannel {
	static func processServiceChannel(named serviceName: String, parameters: Process.ExecutionParameters) async -> DataChannel {
		let process = HostedProcess(named: serviceName, parameters: parameters)
		let sequence = await process.eventSequence.compactMap { event in
			switch event {
			case .stdout(let data):
				return data
			case .stderr, .terminated:
				return nil
			}
		}

		// here's a neat little trick
		var iterator = sequence.makeAsyncIterator()
		let dataStream = AsyncStream { await iterator.next() }

		let channel = DataChannel(writeHandler: { try await process.write($0) },
								  dataSequence: dataStream)

		return channel
	}
}
