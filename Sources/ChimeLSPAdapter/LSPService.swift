import Foundation
import os.log
import UniformTypeIdentifiers

import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol
#if canImport(ProcessEnv)
import ProcessEnv
#endif

public enum LSPServiceError: Error {
    case unsupported
	case providerUnavailable
    case noProjectConnection(URL)
    case noDocumentConnection(DocumentContext)
    case documentURLInvalid(DocumentContext)
	case documentNotFound(DocumentUri)
	case serverNotFound
	case languageNotDefined
}

/// Connect a language server to `ExtensionProtocol`.
@MainActor
public final class LSPService {
    public typealias ExecutionParamsProvider = () async throws -> Process.ExecutionParameters

	public enum Execution {
		case hosted(ExecutionParamsProvider)
		case hostedWithUserShell(ExecutionParamsProvider)
		case unixScript(path: String, arguments: [String])
	}

    private let serverOptions: any Codable
	private let execution: Execution
    private var projectServices: [URL: LSPProjectService]
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "LSPService")

    let host: HostProtocol
    let transformers: LSPTransformers

	/// Write raw LSP messages to the console.
	public let logMessages: Bool

	public init(host: HostProtocol,
				serverOptions: any Codable = [:] as [String: String],
				transformers: LSPTransformers = .init(),
				execution: Execution,
				logMessages: Bool = false) {
		self.host = host
		self.transformers = transformers
		self.projectServices = [:]
		self.serverOptions = serverOptions
		self.execution = execution
		self.logMessages = logMessages
	}

	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initialization procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter executionParamsProvider: A function that produces the configuration required to launch the language server
	/// - Parameter runInUserShell: run the server within the user's shell environment
	/// - Parameter logMessages: log the raw JSON-RPC messages to and from the server
	public convenience init(host: HostProtocol,
				serverOptions: any Codable = [:] as [String: String],
				transformers: LSPTransformers = .init(),
				executionParamsProvider: @escaping ExecutionParamsProvider,
				runInUserShell: Bool = false,
				logMessages: Bool = false) {
		let execution = runInUserShell ? Execution.hostedWithUserShell(executionParamsProvider) : Execution.hosted(executionParamsProvider)

		self.init(
			host: host,
			serverOptions: serverOptions,
			transformers: transformers,
			execution: execution,
			logMessages: logMessages
		)
	}

	#if os(macOS)
	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initialization procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter executableName: The language server executable name found in PATH.
	/// - Parameter logMessages: log the raw JSON-RPC messages to and from the server
	public convenience init(host: HostProtocol,
							serverOptions: any Codable = [:] as [String: String],
							transformers: LSPTransformers = .init(),
							executableName: String,
							logMessages: Bool = false) {
		let provider: ExecutionParamsProvider = {
			try await LSPService.pathExecutableParamsProvider(name: executableName,
															  host: host)
		}

		self.init(host: host,
				  serverOptions: serverOptions,
				  transformers: transformers,
				  executionParamsProvider: provider,
				  logMessages: logMessages)
	}
#endif

    private func connection(for context: DocumentContext) -> LSPProjectService? {
        guard let projContext = context.projectContext else {
            return nil
        }

        return connection(for: projContext)
    }

    private func connection(for context: ProjectContext) -> LSPProjectService? {
        return projectServices[context.url]
    }
}

extension LSPService: ApplicationService {
	public var configuration: ExtensionConfiguration {
		get throws { throw LSPServiceError.unsupported }
	}
	
	public func didOpenProject(with context: ProjectContext) throws {
		let url = context.url

		logger.info("Opening project at \(url, privacy: .public)")
		precondition(projectServices[url] == nil)

		let conn = LSPProjectService(
			context: context,
			host: host,
			serverOptions: serverOptions,
			transformers: transformers,
			execution: execution,
			logMessages: logMessages
		)

		self.projectServices[url] = conn
	}

	public func willCloseProject(with context: ProjectContext) throws {
		let url = context.url

		logger.info("Closing project at \(url, privacy: .public)")

		self.projectServices[url] = nil
	}

	public func didOpenDocument(with context: DocumentContext) throws {
		try connection(for: context)?.didOpenDocument(with: context)
	}

	public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) throws {
		try willCloseDocument(with: oldContext)
		try didOpenDocument(with: newContext)
	}

	public func willCloseDocument(with context: DocumentContext) throws {
		try connection(for: context)?.willCloseDocument(with: context)
	}

	public func documentService(for context: DocumentContext) throws -> (some DocumentService)? {
		try connection(for: context)?.documentService(for: context)
	}

	public func symbolService(for context: ProjectContext) throws -> (some SymbolQueryService)? {
		// error - we need to know about all projects
		guard let conn = projectServices[context.url] else {
			throw LSPServiceError.noProjectConnection(context.url)
		}

		return conn
	}
}

extension LSPService {
	/// Search the user's PATH for an executable
	public static func pathExecutableParamsProvider(name: String, host: HostProtocol) async throws -> Process.ExecutionParameters {
#if os(macOS)
		let userEnv = try await host.captureUserEnvironment()

		let whichParams = Process.ExecutionParameters(path: "/usr/bin/which", arguments: [name], environment: userEnv)

		let data = try await host.launchProcess(with: whichParams).readStdout()
		let output = String(decoding: data, as: UTF8.self)

		if output.isEmpty {
			throw LSPServiceError.serverNotFound
		}

		let path = output.trimmingCharacters(in: .whitespacesAndNewlines)

		return .init(path: path, environment: userEnv)
#else
		throw LSPServiceError.unsupported
#endif
	}
}
