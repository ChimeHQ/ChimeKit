import Foundation
import os.log

import AnyCodable
import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol

actor LSPProjectService {
    let rootURL: URL
    let serverOptions: any Codable
    let server: RestartingServer
    let host: HostProtocol
    private var documentConnections: [DocumentIdentity: LSPDocumentService]
    private var serverCapabilities: ServerCapabilities?
    private let log: OSLog
    let transformers: LSPTransformers
    let executionParamsProvider: LSPService.ExecutionParamsProvider

    init(url: URL,
         host: HostProtocol,
         serverOptions: any Codable = [:] as [String: String],
         transformers: LSPTransformers = .init(),
         executionParamsProvider: @escaping LSPService.ExecutionParamsProvider,
         serviceName: String? = "com.chimehq.ChimeKit.ProcessService") {
        self.rootURL = url
        self.serverOptions = serverOptions
        self.host = host
        self.documentConnections = [:]
        self.transformers = transformers
        self.executionParamsProvider = executionParamsProvider
        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "ProjectLSPConnection")

        let restartingServer = RestartingServer()

        self.server = restartingServer

        let provider: RestartingServer.ServerProvider = {
            let params = try await executionParamsProvider()

            if let serviceName = serviceName {
                let remote = try RemoteLanguageServer(named: serviceName, parameters: params)

                remote.terminationHandler = { [weak restartingServer] in
                    restartingServer?.serverBecameUnavailable()
                }

                return remote
            }

            let local = LocalProcessServer(executionParameters: params)

            local.terminationHandler = { [weak restartingServer] in
                restartingServer?.serverBecameUnavailable()
            }

            return local
        }

        restartingServer.serverProvider = provider
            
        restartingServer.initializeParamsProvider = { [weak self] in self?.provideInitializeParams(block: $0)}
        restartingServer.textDocumentItemProvider = { [weak self] in self?.provideTextDocumentItem(for: $0, block: $1) }
            
        // This is subtle. While shutting down, it is possible for some notifications in come in
        // such that they arrive after this instance has been deallocated but before
        // the actual process has been cleaned up.
        restartingServer.requestHandler = { [weak self] in self?.handleRequest($0, block: $1) }
        restartingServer.notificationHandler = { [weak self] in self?.handleNotification($0, block: $1) }
        restartingServer.serverCapabilitiesChangedHandler = { [weak self] in self?.handleCapabilitiesChanged($0) }
    }

    private func connection(for context: DocumentContext) async throws -> LSPDocumentService {
        guard let conn = documentConnections[context.id] else {
            throw LSPServiceError.noDocumentConnection(context)
        }

        return conn
    }
}

extension LSPProjectService {
    func didOpenDocument(with context: DocumentContext) async throws {
        let id = context.id

        assert(documentConnections[id] == nil)

        let docConnection = LSPDocumentService(server: server,
                                               host: host,
                                               context: context,
                                               transformers: transformers)

        try await docConnection.openIfNeeded()

        assert(documentConnections[id] == nil)
        
        documentConnections[id] = docConnection
    }

    func willCloseDocument(with context: DocumentContext) async throws {
        let id = context.id

        guard let conn = documentConnections[id] else {
            throw LSPServiceError.noDocumentConnection(context)
        }

        try await conn.close()

        self.documentConnections[id] = nil
    }

    func shutdown() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.server.shutdownAndExit { error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return try await connection(for: context)
    }
}

extension LSPProjectService: SymbolQueryService {
    func symbols(matching query: String) async throws -> [Symbol] {
        switch serverCapabilities?.workspaceSymbolProvider {
        case nil:
            throw LSPServiceError.unsupported
        case .optionA(let value):
            if value == false {
                throw LSPServiceError.unsupported
            }
        case .optionB:
            break
        }

        let params = WorkspaceSymbolParams(query: query)
        let result = try await server.workspaceSymbol(params: params)

        return transformers.workspaceSymbolResponseTransformer(result)
    }
}

extension LSPProjectService {
    private nonisolated func provideInitializeParams(block: @escaping (Result<InitializeParams, Error>) -> Void) {
        let processId = Int(ProcessInfo.processInfo.processIdentifier)
        let capabilities = LSPService.clientCapabilities
        let uri = rootURL.absoluteString
        let workspaceFolder = WorkspaceFolder(uri: uri, name: "unnamed")

        let bridgedData = (try? JSONEncoder().encode(serverOptions)) ?? Data()
        let anyCodable = try? JSONDecoder().decode(AnyCodable.self, from: bridgedData)

        let params = InitializeParams(processId: processId,
                                      rootPath: rootURL.path,
                                      rootURI: uri,
                                      initializationOptions: anyCodable,
                                      capabilities: capabilities,
                                      trace: .verbose,
                                      workspaceFolders: [workspaceFolder])

        block(.success(params))
    }

    private nonisolated func provideTextDocumentItem(for uri: DocumentUri, block: @escaping (Result<TextDocumentItem, Error>) -> Void) {
        Task {
            do {
                let item = try await textDocumentItem(for: uri)

                block(.success(item))
            } catch {
                block(.failure(error))
            }
        }
    }

    private func textDocumentItem(for uri: DocumentUri) async throws -> TextDocumentItem {
        guard let docConnection = documentConnections.first(where: { $0.value.uri == uri })?.value else {
            throw RestartingServerError.noURIMatch(uri)
        }

        return try await docConnection.textDocumentItem
    }

    private nonisolated func handleRequest(_ request: ServerRequest, block: @escaping (ServerResult<AnyCodable>) -> Void) {
        switch request {
        case .workspaceConfiguration(let params):
            let emptyObject = Dictionary<String, String>()
            let responseItems = Array(repeating: emptyObject, count: params.items.count)

            let responseParam = AnyCodable(arrayLiteral: responseItems)

            block(.success(responseParam))
        case .clientRegisterCapability(let params):
            os_log("register capability", log: self.log, type: .info)

            for registration in params.serverRegistrations {
                switch registration {
                    // TOOD: need to make this work again
//                case .workspaceDidChangeWatchedFiles(let options):
//                    OperationQueue.main.addOperation {
//                        self.setupWatchers(options.watchers)
//                    }
                default:
                    os_log("registration: %{public}@", log: self.log, type: .info, String(describing: registration))
                }
            }

            block(.success(nil))
        case .clientUnregisterCapability(_):
            os_log("unregister capability", log: self.log, type: .info)
            block(.success(nil))
        case .workspaceSemanticTokenRefresh:
            os_log("token refresh", log: self.log, type: .info)
            block(.success(nil))
        default:
            block(.failure(.handlerUnavailable(request.method.rawValue)))
        }
    }

    private nonisolated func handleNotification(_ notification: ServerNotification, block: @escaping (ServerError?) -> Void) {
        switch notification {
        case .windowShowMessage(let showMessageParams):
            os_log("show message: %{public}@", log: self.log, type: .info, showMessageParams.message)
            block(nil)
        case .windowLogMessage(let logMessageParams):
            os_log("log message: %{public}@", log: self.log, type: .info, logMessageParams.message)
            block(nil)
        case .textDocumentPublishDiagnostics(let params):
            Task {
                await publishDiagnostics(params)
            }
        case .telemetryEvent(let params):
            os_log("telemetry event: %{public}@", log: self.log, type: .info, String(describing: params))
            block(nil)
        case .protocolCancelRequest(let params):
            os_log("cancel request: %{public}@", log: self.log, type: .info, String(describing: params))
            block(nil)
        case .protocolProgress(let params):
            os_log("progress: %{public}@", log: self.log, type: .info, String(describing: params))
            block(nil)
        case .protocolLogTrace(let params):
            os_log("log trace: %{public}@", log: self.log, type: .info, String(describing: params))
            block(nil)
        }
    }

    private nonisolated func handleCapabilitiesChanged(_ capabilities: ServerCapabilities?) {
        Task {
            await self.updateServerCapabilities(capabilities)
        }
    }

    private func updateServerCapabilities(_ capabilities: ServerCapabilities?) {
        os_log("capabilities changed", log: self.log, type: .info)

        self.serverCapabilities = capabilities

        for conn in self.documentConnections.values {
            conn.serverCapabilities = capabilities
        }
    }
}

extension LSPProjectService {
    private func publishDiagnostics(_ params: PublishDiagnosticsParams) {
        let version = params.version
        let count = params.diagnostics.count
        
        os_log("diagnostics count %{public}d with doc version %{public}@", log: self.log, type: .debug, count, String(describing: version))

        guard let url = URL(string: params.uri) else {
            os_log("unable to convert url: %{public}@", log: self.log, type: .info, String(describing: params))
            return
        }

        let usableDiagnostics = params.diagnostics.prefix(100)
        if count > 100 {
            os_log("truncated diagnostics payload", log: self.log, type: .info)
        }

        let transformer = transformers.diagnosticTransformer
        let diagnostics = usableDiagnostics.map({ transformer($0) })

        host.publishDiagnostics(diagnostics, for: url, version: params.version)
    }

//    private func setupWatchers(_ watchers: [FileSystemWatcher]) {
//        OperationQueue.preconditionMain()
//
//        let rootPath = self.rootURL.path
//        self.watchers = watchers.map({ FileWatcher(root: rootPath, params: $0) })
//
//        self.watchers.forEach({
//            $0.start()
//            $0.handler = { [weak self] events in
//                self?.handleWatcherEvents(events)
//            }
//        })
//    }
//
//    private func handleWatcherEvents(_ events: [FileEvent]) {
//        let params = DidChangeWatchedFilesParams(changes: events)
//
//        server.didChangeWatchedFiles(params: params) { [weak self] error in
//            guard let error = error else {
//                return
//            }
//
//            if let log = self?.log {
//                os_log("failed to deliver DidChangeWatchedFiles: %{public}@", log: log, type: .error, String(describing: error))
//            } else {
//                print("failed to deliver DidChangeWatchedFiles", error)
//            }
//        }
//    }
}
