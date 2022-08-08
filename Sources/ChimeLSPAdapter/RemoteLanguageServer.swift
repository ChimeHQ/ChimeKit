import Foundation
import Combine
import os.log

import ConcurrencyPlus
import LanguageServerProtocol
import JSONRPC
import ProcessEnv
import ProcessServiceClient

final class UnrestrictedProcessTransport {
    private var readHandler: ReadHandler = { _ in }
    private let process: HostedProcess
    private let taskQueue = TaskQueue()
    private var subscription: AnyCancellable? = nil
    private let log = OSLog(subsystem: "com.chime.Edit.LSP", category: "RemoteLanguageServer")

    init(process: HostedProcess) {
        self.process = process
    }

    func beginMonitoringProcess() async throws {
        let task = taskQueue.addOperation {
            self.subscription = try await self.process.processEventPublisher
                .sink(receiveCompletion: { _ in
                }, receiveValue: { [weak self] event in
                    switch event {
                    case .stdout(let data):
                        self?.readHandler(data)
                    case .stderr(let data):
                        let output = String(data: data, encoding: .utf8) ?? ""

                        if let log = self?.log {
                            os_log("stderr: %{public}@", log: log, type: .info, output)
                        }
                    default:
                        break
                    }
                })
        }

        try await task.value
    }
}

extension UnrestrictedProcessTransport: DataTransport {
    func write(_ data: Data) {
        taskQueue.addOperation {
            try await self.process.write(data)
        }
    }

    func setReaderHandler(_ handler: @escaping ReadHandler) {
        self.readHandler = handler
    }

    func close() {
        subscription?.cancel()
    }
}

public class RemoteLanguageServer {
    public let wrappedServer: JSONRPCLanguageServer
    private var subscription: AnyCancellable? = nil

    private let process: HostedProcess
    private let taskQueue = TaskQueue()
    public var terminationHandler: (() -> Void)? = nil

    init(parameters: Process.ExecutionParameters) throws {
        self.process = HostedProcess(parameters: parameters)
        let transport = UnrestrictedProcessTransport(process: process)
        self.wrappedServer = JSONRPCLanguageServer(dataTransport: transport)

        taskQueue.addOperation {
            do {
                try await self.process.launch()
                
                self.subscription = try await self.process.processEventPublisher
                    .sink(receiveCompletion: { _ in
                        
                    }, receiveValue: { event in
                        switch event {
                        case .terminated:
                            self.terminationHandler?()
                        default:
                            break
                        }
                    })

                try await transport.beginMonitoringProcess()
            } catch {
                print("failed to launch: ", String(describing: error))
            }
        }
    }
}

extension RemoteLanguageServer: LanguageServerProtocol.Server {
    public var requestHandler: RequestHandler? {
        get { return wrappedServer.requestHandler }
        set { wrappedServer.requestHandler = newValue }
    }

    public var notificationHandler: NotificationHandler? {
        get { wrappedServer.notificationHandler }
        set { wrappedServer.notificationHandler = newValue }
    }

    public func sendNotification(_ notif: ClientNotification, completionHandler: @escaping (ServerError?) -> Void) {
        taskQueue.addOperation {
            self.wrappedServer.sendNotification(notif, completionHandler: completionHandler)
        }
    }

    public func sendRequest<Response: Codable>(_ request: ClientRequest, completionHandler: @escaping (ServerResult<Response>) -> Void) {
        taskQueue.addOperation {
            self.wrappedServer.sendRequest(request, completionHandler: completionHandler)
        }
    }
}
