import Foundation

import JSONRPC
import LanguageServerProtocol
import ProcessEnv
import LanguageClient

actor HostedServer {
	private let channel: Server
	let requestSequence: RequestSequence
	let notificationSequence: NotificationSequence

	init(named serviceName: String, parameters: Process.ExecutionParameters) async {
		let dataChannel = await DataChannel.processServiceChannel(named: serviceName, parameters: parameters)
		self.channel = JSONRPCServer(dataChannel: dataChannel)

		var noteIterator = channel.notificationSequence.makeAsyncIterator()
		self.notificationSequence = AsyncStream { await noteIterator.next() }

		var reqIterator = channel.requestSequence.makeAsyncIterator()
		self.requestSequence = AsyncStream { await reqIterator.next() }
	}
}

extension HostedServer: Server {
	func sendNotification(_ notif: ClientNotification) async throws {
		try await channel.sendNotification(notif)
	}
	
	func sendRequest<Response>(_ request: ClientRequest) async throws -> Response where Response : Decodable, Response : Sendable {
		try await channel.sendRequest(request)
	}
}
