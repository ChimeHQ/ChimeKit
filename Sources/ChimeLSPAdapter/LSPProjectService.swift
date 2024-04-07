import Foundation
import OSLog

import ChimeExtensionInterface
import JSONRPC
import LanguageClient
import LanguageServerProtocol
import Queue

@MainActor
final class LSPProjectService {
	typealias Server = LanguageClient.RestartingServer<JSONRPCServerConnection>

	private let execution: LSPService.Execution
	private let serverOptions: any Codable
	private let transformers: LSPTransformers
	private let host: HostProtocol
	private let logMessages: Bool
	private var documentConnections = [DocumentIdentity: LSPDocumentService]()
	private let queue = AsyncQueue(attributes: [.concurrent, .publishErrors])
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "LSPProjectService")
	private var requestTask: Task<Void, Error>?
	private var capabilitiesTask: Task<Void, Error>?
	private var fileEventTasks = [Task<Void, Error>]()
	private var hostedProcess: LaunchedProcess?
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
		execution: LSPService.Execution,
		logMessages: Bool
	) {
		self.context = context
		self.host = host
		self.serverOptions = serverOptions
		self.transformers = transformers
		self.execution = execution
		self.logMessages = logMessages

		let eventSequence = serverHostInterface.server.eventSequence

		self.requestTask = Task { [weak self, eventSequence] in
			for await event in eventSequence {
				self?.handleEvent(event)
			}
		}

		let capabilitiesSequence = serverHostInterface.server.capabilitiesSequence

		self.capabilitiesTask = Task { [weak self, capabilitiesSequence] in
			for await capabilities in capabilitiesSequence {
				self?.handleCapabilitiesChanged(capabilities)
			}
		}

		Task {
			for await error in queue.errorSequence {
				logger.error("queued failure: \(error, privacy: .public)")
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
	private nonisolated func nonisolatedConnectionInvalidated(_ error: Error?) {
		Task {
			await connectionInvalidated(error)
		}
	}

	private func connectionInvalidated(_ error: Error?) async {
		logger.warning("channel connection invalidated: \(error, privacy: .public)")

		await serverHostInterface.server.connectionInvalidated()
	}

	private func makeDataChannel() async throws -> DataChannel {
		guard #available(macOS 12.0, *) else {
			throw LSPServiceError.unsupported
		}

#if os(macOS)
		switch execution {
		case let .hosted(provider):
			let params = try await provider()

			return try await DataChannel.hostedProcessChannel(
				host: host,
				parameters: params,
				runInUserShell: false,
				terminationHandler: { [weak self] in self?.nonisolatedConnectionInvalidated(nil) }
			)
		case let .hostedWithUserShell(provider):
			let params = try await provider()

			return try await DataChannel.hostedProcessChannel(
				host: host,
				parameters: params,
				runInUserShell: true,
				terminationHandler: { [weak self] in self?.nonisolatedConnectionInvalidated(nil) }
			)
		case let .unixScript(path: path, arguments: args):
			return try DataChannel.userScriptChannel(
				scriptPath: path,
				arguments: args,
				terminationHandler: { [weak self] in self?.nonisolatedConnectionInvalidated($0) }
			)
		}
#else
		return DataChannel(writeHandler: {
			data in
				throw LSPServiceError.unsupported
			},
			dataSequence: DataChannel.DataSequence(unfolding: { nil })
		)
#endif
	}

	private func loggingChannel(_ channel: DataChannel) -> DataChannel {
		DataChannel.tap(channel: channel, onRead: { data in
			print("read: ", String(decoding: data, as: UTF8.self))
		}, onWrite: { data in
			print("write: ", String(decoding: data, as: UTF8.self))
		})
	}

	private func serverChannelProvider() async throws -> JSONRPCServerConnection {
		let dataChannel = try await makeDataChannel()

		let channel = logMessages ? loggingChannel(dataChannel) : dataChannel

		return JSONRPCServerConnection(dataChannel: channel)
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
	private func handleEvent(_ event: ServerEvent) {
		queue.addOperation {
			switch event {
			case let .request(_, .workspaceConfiguration(params, handler)):
				let count = params.items.count
				let emptyObject = JSONValue.hash([:])
				let responseItems = Array(repeating: emptyObject, count: count)

				await handler(.success(responseItems))
			case let .request(_, .workspaceSemanticTokenRefresh(handler)):
				self.logger.info("semantic token refresh")

				for docId in self.documentConnections.keys {
					self.host.invalidateTokens(for: docId, in: .all)
				}

				await handler(nil)
			case let .request(_, .clientRegisterCapability(params, handler)):
				let methods = params.registrations.map({ $0.method })
				
				self.logger.info("Registering capabilities: \(methods, privacy: .public)")

				self.handleServerRegistrations(params.serverRegistrations)

				await handler(nil)
			case let .request(_, .clientUnregisterCapability(params, handler)):
				let methods = params.unregistrations.map({ $0.method })

				self.logger.warning("Unregistering capabilities: \(methods, privacy: .public)")
				await handler(nil)
			case let .request(id: _, request: request):
				await request.relyWithError(LSPServiceError.unsupported)
			case let .notification(.textDocumentPublishDiagnostics(params)):
				self.publishDiagnostics(params)
			default:
				let eventStr = String(describing: event)

				self.logger.info("dropping unhandled server event: \(eventStr, privacy: .public)")
			}
		}
	}

	private func handleServerRegistrations(_ registrations: [ServerRegistration]) {
		for registration in registrations {
			logger.info("Server registration: \(registration.method.rawValue, privacy: .public)")

			switch registration {
#if os(macOS)
			case let .workspaceDidChangeWatchedFiles(options):
				setupFileWatchers(options.watchers)
#endif
			default:
				break
			}
		}
	}

#if os(macOS)
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
#endif

	private func handleFileEvent(_ event: FileEvent) {
		let params = DidChangeWatchedFilesParams(changes: [event])

		serverHostInterface.enqueue(barrier: true) { server, _, _ in
			try await server.workspaceDidChangeWatchedFiles(params)
		}
	}

	private func handleCapabilitiesChanged(_ capabilities: ServerCapabilities) {
		logger.notice("new capabilities")

		for conn in documentConnections.values {
			conn.handleCapabilitiesChanged(capabilities)
		}
	}

	private func publishDiagnostics(_ params: PublishDiagnosticsParams) {
		let version = params.version
		let versionStr = version.flatMap { String($0) } ?? "nil"
		let count = params.diagnostics.count

		logger.debug("diagnostics count \(count, privacy: .public) with doc version \(versionStr, privacy: .public)")

		guard let url = URL(string: params.uri) else {
			let paramsStr = String(describing: params)

			logger.warning("unable to convert url: \(paramsStr, privacy: .public)")

			return
		}

		let usableDiagnostics = params.diagnostics.prefix(100)
		if count > 100 {
			logger.info("truncated diagnostics payload")
		}

		let transformer = transformers.diagnosticTransformer
		let diagnostics = usableDiagnostics.map({ transformer($0) })

		host.publishDiagnostics(diagnostics, for: url, version: version)
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

		guard docConnection.isOpenable else {
			logger.warning("Document connection is not openable: \(docContext.languageIdentifier ?? "")")
			return
		}

		serverHostInterface.enqueue(barrier: true) { server, _, _ in
			do {
				let item = try await docConnection.textDocumentItem

				let params = DidOpenTextDocumentParams(textDocument: item)
				try await server.textDocumentDidOpen(params)
			} catch {
				self.logger.error("Failed to execute textDocumentDidOpen: \(error, privacy: .public)")
			}
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

		serverHostInterface.enqueue(barrier: true) { server, _, _ in
			let id = try docContext.textDocumentIdentifier

			let param = DidCloseTextDocumentParams(textDocument: id)
			try await server.textDocumentDidClose(param)
		}
	}

	func documentService(for docContext: DocumentContext) throws -> (some DocumentService)? {
		let id = docContext.id
		let conn = documentConnections[id]

		if conn == nil {
			logger.error("No connection for \(docContext, privacy: .public)")
			assertionFailure()
		}

		return conn
	}

	func symbolService(for context: ProjectContext) throws -> (some SymbolQueryService)? {
		self
	}
}

extension LSPProjectService: SymbolQueryService {
	func symbols(matching query: String) async throws -> [Symbol] {
		try await serverHostInterface.operationValue { (server, transformers, _) in
			// we have to request capabilities here, as the server may not be started at this
			// point
			let caps = try await server.initializeIfNeeded().capabilities

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
			let result = try await server.workspaceSymbol(params)

			return transformers.workspaceSymbolResponseTransformer(result)
		}
	}
}
