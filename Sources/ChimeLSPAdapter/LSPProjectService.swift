import Foundation
import os.log

import AnyCodable
import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol

actor LSPProjectService {
	let context: ProjectContext
    let serverOptions: any Codable
    let server: RestartingServer
    let host: HostProtocol
    private var documentConnections: [DocumentIdentity: LSPDocumentService]
    private let log: OSLog
	private var watchers = [FileWatcher]()
    let transformers: LSPTransformers
    let executionParamsProvider: LSPService.ExecutionParamsProvider
	let contextFilter: LSPService.ContextFilter

    init(context: ProjectContext,
         host: HostProtocol,
         serverOptions: any Codable = [:] as [String: String],
         transformers: LSPTransformers = .init(),
		 contextFilter: @escaping LSPService.ContextFilter,
         executionParamsProvider: @escaping LSPService.ExecutionParamsProvider,
		 processHostServiceName: String?,
		 logMessages: Bool) {
        self.context = context
        self.serverOptions = serverOptions
        self.host = host
        self.documentConnections = [:]
        self.transformers = transformers
        self.executionParamsProvider = executionParamsProvider
		self.contextFilter = contextFilter
        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "LSPProjectService")

        let restartingServer = RestartingServer()

        self.server = restartingServer

        let provider: RestartingServer.ServerProvider = {
            let params = try await executionParamsProvider()

            if let serviceName = processHostServiceName {
                let remote = try RemoteLanguageServer(named: serviceName, parameters: params)

                remote.terminationHandler = { [weak restartingServer] in
                    restartingServer?.serverBecameUnavailable()
                }

				remote.logMessages = logMessages

                return remote
            }

            let local = LocalProcessServer(executionParameters: params)

            local.terminationHandler = { [weak restartingServer] in
                restartingServer?.serverBecameUnavailable()
            }

			local.logMessages = logMessages

            return local
        }

        restartingServer.serverProvider = provider
            
        restartingServer.initializeParamsProvider = { [weak self] in
			guard let self = self else {
				throw LSPServiceError.providerUnavailable
			}

			return try await self.provideInitializeParams()
		}

        restartingServer.textDocumentItemProvider = { [weak self] in
			guard let self = self else {
				throw LSPServiceError.providerUnavailable
			}

			return try await self.textDocumentItem(for: $0)
		}
            
        // This is subtle. While shutting down, it is possible for some notifications in come in
        // such that they arrive after this instance has been deallocated but before
        // the actual process has been cleaned up.
        restartingServer.requestHandler = { [weak self] in self?.handleRequest($0, block: $1) }
        restartingServer.notificationHandler = { [weak self] in self?.handleNotification($0, block: $1) }
        restartingServer.serverCapabilitiesChangedHandler = { [weak self] in self?.handleCapabilitiesChanged($0) }
    }

	nonisolated var rootURL: URL {
		return context.url
	}

    private func connection(for docContext: DocumentContext) async throws -> LSPDocumentService {
        guard let conn = documentConnections[docContext.id] else {
            throw LSPServiceError.noDocumentConnection(docContext)
        }

        return conn
    }
}

extension LSPProjectService {
    func didOpenDocument(with docContext: DocumentContext) async throws {
        let id = docContext.id

        assert(documentConnections[id] == nil)

		let filter: LSPDocumentService.ContextFilter = { [weak self] in
			guard let self = self else { return false }

			return await self.contextFilter(self.context, $0)
		}
		
        let docConnection = LSPDocumentService(server: server,
                                               host: host,
                                               context: docContext,
                                               transformers: transformers,
											   contextFilter: filter)

		try await docConnection.openIfNeeded()

        assert(documentConnections[id] == nil)
        
        documentConnections[id] = docConnection
    }

    func willCloseDocument(with docContext: DocumentContext) async throws {
        let id = docContext.id

        guard let conn = documentConnections[id] else {
            throw LSPServiceError.noDocumentConnection(docContext)
        }

		// This is a little risky, as we could potentially return a different
		// value here, and not close...
		if await contextFilter(context, docContext) {
			try await conn.close()
		}

        self.documentConnections[id] = nil
    }

    func shutdown() async throws {
		// always try to really shutdown, as we really don't want to leak
		// server processes
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

    func documentService(for docContext: DocumentContext) async throws -> DocumentService? {
        return try await connection(for: docContext)
    }
}

extension LSPProjectService: SymbolQueryService {
    func symbols(matching query: String) async throws -> [Symbol] {
		// this check is important, to ensure that we do not start up a server
		// unless there is a reasonable expectation we could get results
		guard await contextFilter(context, nil) == true else { return [] }

		// we have to request capabilities here, as the server may not be started at this
		// point
		let caps = try await server.capabilities

        switch caps.workspaceSymbolProvider {
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
    private func provideInitializeParams() throws -> InitializeParams {
        let processId = Int(ProcessInfo.processInfo.processIdentifier)
        let capabilities = LSPService.clientCapabilities

		let uri = rootURL.absoluteString
		let path = rootURL.path
		let workspaceFolder = WorkspaceFolder(uri: uri, name: "unnamed")

		let bridgedData = (try? JSONEncoder().encode(serverOptions)) ?? Data()
		let anyCodable = try? JSONDecoder().decode(AnyCodable.self, from: bridgedData)

		return InitializeParams(processId: processId,
								rootPath: path,
								rootURI: uri,
								initializationOptions: anyCodable,
								capabilities: capabilities,
								trace: .verbose,
								workspaceFolders: [workspaceFolder])
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
                case .workspaceDidChangeWatchedFiles(let options):
					Task {
						await self.setupWatchers(options.watchers)
					}
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

    private func setupWatchers(_ fsWatchers: [FileSystemWatcher]) {
        let rootPath = self.rootURL.path

		for watcher in watchers {
			watcher.stop()
		}

        self.watchers = fsWatchers.map({ FileWatcher(root: rootPath, params: $0) })

		for watcher in watchers {
			watcher.start()
			watcher.handler = { [weak self] in self?.handleWatcherEvents($0) }
		}
    }

    private nonisolated func handleWatcherEvents(_ events: [FileEvent]) {
        let params = DidChangeWatchedFilesParams(changes: events)

		Task {
			do {
				try await self.server.didChangeWatchedFiles(params: params)
			} catch {
				os_log("failed to deliver DidChangeWatchedFiles: %{public}@", log: self.log, type: .error, String(describing: error))
			}
		}
    }
}
