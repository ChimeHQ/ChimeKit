//import Foundation
//import Combine
//import os.log
//
//import ConcurrencyPlus
//import LanguageClient
//import LanguageServerProtocol
//import JSONRPC
//import ProcessEnv
//import ProcessServiceClient
//
//final class UnrestrictedProcessTransport {
//    private var readHandler: ReadHandler = { _ in }
//    private let process: HostedProcess
//    private let taskQueue = TaskQueue()
//    private var subscription: AnyCancellable? = nil
//    private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "UnrestrictedProcessTransport")
//
//    init(process: HostedProcess) {
//        self.process = process
//    }
//
//    func beginMonitoringProcess() async throws {
//        let task = taskQueue.addOperation {
//            self.subscription = try await self.process.processEventPublisher
//                .sink(receiveCompletion: { _ in
//                }, receiveValue: { [weak self] event in
//                    switch event {
//                    case .stdout(let data):
//                        self?.readHandler(data)
//                    case .stderr(let data):
//                        let output = String(data: data, encoding: .utf8) ?? ""
//
//                        self?.logger.info("stderr: \(output, privacy: .public)")
//                    default:
//                        break
//                    }
//                })
//        }
//
//        try await task.value
//    }
//}
//
//extension UnrestrictedProcessTransport: DataTransport {
//    func write(_ data: Data) {
//        taskQueue.addOperation {
//            try await self.process.write(data)
//        }
//    }
//
//    func setReaderHandler(_ handler: @escaping ReadHandler) {
//        self.readHandler = handler
//    }
//
//    func close() {
//        subscription?.cancel()
//    }
//}
//
///// Provides an interface to a LSP language server hosted by an intermediary process.
//final class RemoteLanguageServer {
//    private let wrappedServer: JSONRPCLanguageServer
//    private var subscription: AnyCancellable? = nil
//    private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "RemoteLanguageServer")
//
//    private let process: HostedProcess
//    private let taskQueue = TaskQueue()
//	private let requestStreamTap = AsyncStreamTap<ServerRequest>()
//	private let notificationStreamTap = AsyncStreamTap<ServerNotification>()
//
//    public var terminationHandler: (() -> Void)? = nil
//
//    init(named serviceName: String, parameters: Process.ExecutionParameters) throws {
//        self.process = HostedProcess(named: serviceName, parameters: parameters)
//
//        let transport = UnrestrictedProcessTransport(process: process)
//		let channel = DataChannel.transportChannel(with: transport)
//
//        self.wrappedServer = JSONRPCLanguageServer(channel: channel)
//
//        taskQueue.addOperation {
//			self.logger.debug("launching remote server")
//
//            do {
//                try await self.process.launch()
//                
//                self.subscription = try await self.process.processEventPublisher
//                    .sink(receiveCompletion: { _ in
//                        
//                    }, receiveValue: { event in
//                        switch event {
//                        case .terminated:
//                            self.terminationHandler?()
//                        default:
//                            break
//                        }
//                    })
//
//                try await transport.beginMonitoringProcess()
//            } catch {
//                self.logger.error("failed to launch: \(String(describing: error), privacy: .public)")
//            }
//        }
//
//		Task {
//			await monitorServer()
//		}
//    }
//
//	private func monitorServer() async {
//		await requestStreamTap.setInputStream(wrappedServer.requestSequence)
//		await notificationStreamTap.setInputStream(wrappedServer.notificationSequence)
//	}
//
//    private func stopProcess() {
//        self.taskQueue.addOperation {
//            do {
//                try await self.process.terminate()
//            } catch {
//                self.logger.error("failed to terminate: \(String(describing: error), privacy: .public)")
//            }
//        }
//    }
//
////	public var logMessages: Bool {
////		get { return wrappedServer.logMessages }
////		set { wrappedServer.logMessages = newValue }
////	}
//}
//
//extension RemoteLanguageServer: Server {
//	public nonisolated var notificationSequence: NotificationSequence {
//		notificationStreamTap.stream
//	}
//
//	public nonisolated var requestSequence: RequestSequence {
//		requestStreamTap.stream
//	}
//
//	public func sendNotification(_ notif: ClientNotification) async throws {
//		try await wrappedServer.sendNotification(notif)
//	}
//
//	public func sendRequest<Response>(_ request: ClientRequest) async throws -> Response where Response : Decodable, Response : Sendable {
//		let value: Response = try await wrappedServer.sendRequest(request)
//
//		if case .shutdown = request {
//			stopProcess()
//		}
//
//		return value
//	}
//}
