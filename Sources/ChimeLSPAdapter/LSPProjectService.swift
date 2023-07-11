import Foundation
import OSLog

import ChimeExtensionInterface
import JSONRPC
import LanguageClient
import LanguageServerProtocol
import Queue

@MainActor
final class LSPProjectService {
	typealias Server = LanguageClient.RestartingServer<JSONRPCServer>

	private let processHostServiceName: String?
	private let executionParamsProvider: LSPService.ExecutionParamsProvider
	private let serverOptions: any Codable
	private let transformers: LSPTransformers
	private let host: HostProtocol
	private var documentConnections = [DocumentIdentity: LSPDocumentService]()
	private let queue = AsyncQueue(attributes: [.concurrent, .publishErrors])
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "LSPProjectService")
	private var requestTask: Task<Void, Error>?
	private var capabilitiesTask: Task<Void, Error>?
	private var fileEventTasks = [Task<Void, Error>]()
	private lazy var serverHostInterface: LSPHostServerInterface = {
		let server = Server(configuration: serverConfig)

		return LSPHostServerInterface(host: host,
									  server: server,
									  queue: queue,
									  transformers: transformers)
	}()

	let context: ProjectContext

	init(
		context: ProjectContext,
		host: HostProtocol,
		serverOptions: any Codable = [:] as [String: String],
		transformers: LSPTransformers = .init(),
		executionParamsProvider: @escaping LSPService.ExecutionParamsProvider,
		processHostServiceName: String?,
		logMessages: Bool
	) {
		self.context = context
		self.host = host
		self.serverOptions = serverOptions
		self.transformers = transformers
		self.processHostServiceName = processHostServiceName
		self.executionParamsProvider = executionParamsProvider

		let requestSequence = serverHostInterface.server.requestSequence

		self.requestTask = Task { [weak self, requestSequence] in
			for await request in requestSequence {
				self?.handleRequest(request)
			}
		}

		let capabilitiesSequence = serverHostInterface.server.capabilitiesSequence

		self.capabilitiesTask = Task { [weak self, capabilitiesSequence] in
			for await capabilities in capabilitiesSequence {
				self?.handleCapabilitiesChanged(capabilities)
			}
		}
	}

	deinit {
		requestTask = nil
	}

	nonisolated var rootURL: URL {
		return context.url
	}
}

extension LSPProjectService {
	private func makeDataChannel() async throws -> DataChannel {
		let params = try await executionParamsProvider()

		guard let serviceName = processHostServiceName else {
			return try DataChannel.localProcessChannel(parameters: params)
		}

		return await DataChannel.processServiceChannel(named: serviceName, parameters: params)
	}

	private func serverChannelProvider() async throws -> JSONRPCServer {
		let dataChannel = try await makeDataChannel()

		return JSONRPCServer(dataChannel: dataChannel)
	}

	private func textDocumentItem(for uri: DocumentUri) async throws -> TextDocumentItem {
		guard let docConnection = documentConnections.first(where: { $0.value.uri == uri })?.value else {
			throw LSPServiceError.documentNotFound(uri)
		}

		return try await docConnection.textDocumentItem
	}

	private func initializeParams() throws -> InitializeParams {
		let processId = Int(ProcessInfo.processInfo.processIdentifier)
		let capabilities = LSPService.clientCapabilities

		let uri = rootURL.absoluteString
		let path = rootURL.path
		let workspaceFolder = WorkspaceFolder(uri: uri, name: "unnamed")

		let bridgedData = (try? JSONEncoder().encode(serverOptions)) ?? Data()
		let opts = try? JSONDecoder().decode(LSPAny.self, from: bridgedData)
		let locale = Locale.current.identifier

		return InitializeParams(processId: processId,
								locale: locale,
								rootPath: path,
								rootUri: uri,
								initializationOptions: opts,
								capabilities: capabilities,
								trace: .verbose,
								workspaceFolders: [workspaceFolder])
	}

	private var serverConfig: Server.Configuration {
		let serverProvider: Server.ServerProvider = { [weak self] in
			guard let self = self else { throw LSPServiceError.providerUnavailable }

			return try await self.serverChannelProvider()
		}

		let docItemProvider: Server.TextDocumentItemProvider = { [weak self] in
			guard let self = self else { throw LSPServiceError.providerUnavailable }

			return try await self.textDocumentItem(for: $0)
		}

		let initializeParamsProvider: Server.InitializeParamsProvider = { [weak self] in
			guard let self = self else { throw LSPServiceError.providerUnavailable }

			return try await self.initializeParams()
		}

		return Server.Configuration(serverProvider: serverProvider,
									textDocumentItemProvider: docItemProvider,
									initializeParamsProvider: initializeParamsProvider)
	}
}

extension LSPProjectService {
	private func handleRequest(_ request: ServerRequest) {
		queue.addOperation {
			switch request {
			case let .workspaceConfiguration(params, handler):
				let count = params.items.count
				let emptyObject = JSONValue.hash([:])
				let responseItems = Array(repeating: emptyObject, count: count)

				await handler(.success(responseItems))
			case let .workspaceSemanticTokenRefresh(handler):
				self.logger.info("semantic token refresh")

				for docId in self.documentConnections.keys {
					self.host.invalidateTokens(for: docId, in: .all)
				}

				await handler(nil)
			case let .clientRegisterCapability(params, handler):
				let methods = params.registrations.map({ $0.method })
				
				self.logger.info("Registering capabilities: \(methods, privacy: .public)")

				self.handleServerRegistrations(params.serverRegistrations)

				await handler(nil)
			case let .clientUnregisterCapability(params, handler):
				let methods = params.unregistrations.map({ $0.method })

				self.logger.warning("Unregistering capabilities: \(methods, privacy: .public)")
				await handler(nil)
			default:
				await request.relyWithError(LSPServiceError.unsupported)
			}
		}
	}

	private func handleServerRegistrations(_ registrations: [ServerRegistration]) {
		for registration in registrations {
			logger.info("Server registration: \(registration.method.rawValue, privacy: .public)")

			switch registration {
			case let .workspaceDidChangeWatchedFiles(options):
				setupFileWatchers(options.watchers)
			default:
				break
			}
		}
	}

	private func setupFileWatchers(_ watchers: [FileSystemWatcher]) {
		self.fileEventTasks = watchers.compactMap {
			do {
				return try FileEventAsyncSequence(watcher: $0, root: rootURL)
			} catch {
				logger.warning("Unable to create file event sequence: \(error, privacy: .public)")
				return nil
			}
		}.map { (sequence: FileEventAsyncSequence) in
			Task { [weak self] in
				for await event in sequence {
					guard let self = self else { return }

					self.handleFileEvent(event)
				}
			}
		}

	}

	private func handleFileEvent(_ event: FileEvent) {
		let params = DidChangeWatchedFilesParams(changes: [event])

		serverHostInterface.enqueueBarrier { server, _, _ in
			try await server.didChangeWatchedFiles(params: params)
		}
	}

	private func handleCapabilitiesChanged(_ capabilities: ServerCapabilities) {
		print("new capabilities: ", capabilities)

		for conn in documentConnections.values {
			conn.handleCapabiltiesChanged(capabilities)
		}
	}
}

extension LSPProjectService: ApplicationService {
	var configuration: ExtensionConfiguration {
		get throws { throw LSPServiceError.unsupported  }
	}
	
	func didOpenProject(with context: ProjectContext) throws {
		throw LSPServiceError.unsupported
	}
	
	func willCloseProject(with context: ProjectContext) throws {
		throw LSPServiceError.unsupported
	}

	func didOpenDocument(with docContext: DocumentContext) throws {
		let id = docContext.id

		logger.debug("Opening document: \(docContext, privacy: .public)")

		assert(documentConnections[id] == nil)

		let docConnection = LSPDocumentService(serverHostInterface: serverHostInterface,
												  context: docContext)

		documentConnections[id] = docConnection

		guard docConnection.isOpenable else { return }

		serverHostInterface.enqueueBarrier { server, _, _ in
			let item = try await docConnection.textDocumentItem

			let params = DidOpenTextDocumentParams(textDocument: item)
			try await server.didOpenTextDocument(params: params)
		}
	}

	func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws {
		try willCloseDocument(with: oldContext)
		try didOpenDocument(with: newContext)
	}

	func willCloseDocument(with docContext: DocumentContext) throws {
		let id = docContext.id

		logger.debug("Closing document: \(docContext, privacy: .public)")

		let connection = documentConnections[id]

		assert(connection != nil)

		self.documentConnections[id] = nil

		guard connection?.isOpenable == true else { return }

		serverHostInterface.enqueueBarrier { server, _, _ in
			let id = try docContext.textDocumentIdentifier
			
			let param = DidCloseTextDocumentParams(textDocument: id)
			try await server.didCloseTextDocument(params: param)
		}
	}

	func documentService(for docContext: DocumentContext) throws -> DocumentService? {
		let id = docContext.id
		let conn = documentConnections[id]

		assert(conn != nil)

		return conn
	}

	func symbolService(for context: ProjectContext) throws -> SymbolQueryService? {
		self
	}
}

extension LSPProjectService: SymbolQueryService {
	func symbols(matching query: String) async throws -> [Symbol] {
		try await serverHostInterface.operationValue { (server, transformers, _) in
			// we have to request capabilities here, as the server may not be started at this
			// point
			let caps = try await server.initializeIfNeeded()

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
}
