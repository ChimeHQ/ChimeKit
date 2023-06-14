import Foundation
import os.log
import UniformTypeIdentifiers

import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol
import ProcessEnv
import ProcessServiceClient

public enum LSPServiceError: Error {
    case unsupported
	case providerUnavailable
    case noProjectConnection(URL)
    case noDocumentConnection(DocumentContext)
    case documentURLInvalid(DocumentContext)
	case serverNotFound
}

/// Connect a language server to `ExtensionProtocol`.
@MainActor
public final class LSPService {
    public typealias ExecutionParamsProvider = () async throws -> Process.ExecutionParameters
	public typealias ContextFilter = (ProjectContext, DocumentContext?) async -> Bool

    private let serverOptions: any Codable
    private let executionParamsProvider: ExecutionParamsProvider
	private let contextFilter: ContextFilter
    private var projectServices: [URL: LSPProjectService]
	private let logger = Logger(subsystem: "com.chimehq.ChimeKit", category: "LSPService")

    let host: HostProtocol
    let transformers: LSPTransformers

	/// The name of the XPC service used to launch and run the language server executable.
	public let processHostServiceName: String?

	/// Write raw LSP messages to the console.
	public let logMessages: Bool

	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initialization procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter contextFilter: A function that determines which directories and files this server should interact with.
	/// - Parameter executionParamsProvider: A function that produces the configuration required to launch the language server executable.
	/// - Parameter processHostServiceName: The name of the XPC service used to launch and run the language server executable.
	@available(*, deprecated, message: "Use of ContextFilter should be replaced with ExtensionConfiguration")
    public init(host: HostProtocol,
                serverOptions: any Codable = [:] as [String: String],
                transformers: LSPTransformers = .init(),
				contextFilter: @escaping ContextFilter,
                executionParamsProvider: @escaping ExecutionParamsProvider,
				processHostServiceName: String?,
				logMessages: Bool = false) {
        self.host = host
        self.transformers = transformers
        self.projectServices = [:]
        self.serverOptions = serverOptions
        self.executionParamsProvider = executionParamsProvider
		self.contextFilter = contextFilter
		self.processHostServiceName = processHostServiceName
		self.logMessages = logMessages
    }

	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initialization procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter executionParamsProvider: A function that produces the configuration required to launch the language server executable.
	/// - Parameter processHostServiceName: The name of the XPC service used to launch and run the language server executable.
	public init(host: HostProtocol,
				serverOptions: any Codable = [:] as [String: String],
				transformers: LSPTransformers = .init(),
				executionParamsProvider: @escaping ExecutionParamsProvider,
				processHostServiceName: String?,
				logMessages: Bool = false) {
		self.host = host
		self.transformers = transformers
		self.projectServices = [:]
		self.serverOptions = serverOptions
		self.executionParamsProvider = executionParamsProvider
		self.contextFilter = { _, _ in return true }
		self.processHostServiceName = processHostServiceName
		self.logMessages = logMessages
	}

	@available(*, deprecated, message: "Use of ContextFilter should be replaced with ExtensionConfiguration")
	public convenience init(host: HostProtocol,
				serverOptions: any Codable = [:] as [String: String],
				transformers: LSPTransformers = .init(),
				contextFilter: @escaping ContextFilter,
				executableName: String,
				processHostServiceName: String,
				logMessages: Bool = false) {
		let provider: ExecutionParamsProvider = {
			try await LSPService.pathExecutableParamsProvider(name: executableName,
															  processServiceHostName: processHostServiceName)
		}

		self.init(host: host,
				  serverOptions: serverOptions,
				  transformers: transformers,
				  contextFilter: contextFilter,
				  executionParamsProvider: provider,
				  processHostServiceName: processHostServiceName,
				  logMessages: logMessages)
	}

	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initialization procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter executableName: The language server executable name found in PATH.
	/// - Parameter processHostServiceName: The name of the XPC service used to launch and run the language server executable.
	public convenience init(host: HostProtocol,
				serverOptions: any Codable = [:] as [String: String],
				transformers: LSPTransformers = .init(),
				executableName: String,
				processHostServiceName: String,
				logMessages: Bool = false) {
		let provider: ExecutionParamsProvider = {
			try await LSPService.pathExecutableParamsProvider(name: executableName,
															  processServiceHostName: processHostServiceName)
		}

		self.init(host: host,
				  serverOptions: serverOptions,
				  transformers: transformers,
				  executionParamsProvider: provider,
				  processHostServiceName: processHostServiceName,
				  logMessages: logMessages)
	}

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

extension LSPService: ExtensionProtocol {
	public var configuration: ExtensionConfiguration {
		get async throws {
			throw LSPServiceError.unsupported
		}
	}

    public func didOpenProject(with context: ProjectContext) async throws {
        let url = context.url

		logger.info("Opening project at \(url, privacy: .public)")
        precondition(projectServices[url] == nil)

        let conn = LSPProjectService(context: context,
                                     host: host,
                                     serverOptions: serverOptions,
                                     transformers: transformers,
									 contextFilter: contextFilter,
                                     executionParamsProvider: executionParamsProvider,
									 processHostServiceName: processHostServiceName,
									 logMessages: logMessages)

        self.projectServices[url] = conn
    }

    public func willCloseProject(with context: ProjectContext) async throws {
        let url = context.url
        let conn = projectServices[url]

		logger.info("Closing project at \(url, privacy: .public)")
        self.projectServices[url] = nil

        if let conn {
            try await conn.shutdown()
        }

		logger.info("Closed project at \(url, privacy: .public)")
    }

    public func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
        // error - we need to know about all projects
        guard let conn = projectServices[context.url] else {
            throw LSPServiceError.noProjectConnection(context.url)
        }

        return conn
    }

    public func didOpenDocument(with context: DocumentContext) async throws -> URL? {
        let conn = connection(for: context)

        try await conn?.didOpenDocument(with: context)

        return nil
    }

    public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
        try await willCloseDocument(with: oldContext)
        let _ = try await didOpenDocument(with: newContext)
    }

    public func willCloseDocument(with context: DocumentContext) async throws {
        let conn = connection(for: context)

        try await conn?.willCloseDocument(with: context)
    }

    public func documentService(for context: DocumentContext) async throws -> DocumentService? {
        return try await connection(for: context)?.documentService(for: context)
    }
}

@available(*, deprecated, message: "Use ExtensionConfiguration instead")
extension LSPService {
    /// Produce a simple `ContextFilter` that examines file UTIs and marker files
    ///
    /// The returned function will return true if the supplied document conforms
    /// to one of the UTIs within `types`, or if the project root contains at least
    /// one conforming file or file matching `projectFiles`.
	public static func contextFilter(for types: [UTType], projectFiles: Set<String> = []) -> ContextFilter {
        return { (projectContext: ProjectContext, documentContext: DocumentContext?) async -> Bool in
            if let uti = documentContext?.uti {
                if types.contains(where: { uti.conforms(to: $0) }) {
                    return true
                }
            }

			return LSPService.projectRoot(at: projectContext.url, types: types, projectFiles: projectFiles)
        }
    }

	private static func projectRoot(at url: URL, types: [UTType], projectFiles: Set<String>) -> Bool {
        let enumerator = FileManager.default.enumerator(at: url,
                                                        includingPropertiesForKeys: [.contentTypeKey],
                                                        options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])

        while let item = enumerator?.nextObject() as? URL {
			if projectFiles.contains(item.lastPathComponent) {
				return true
			}

            let values = try? item.resourceValues(forKeys: [.contentTypeKey])

            guard let uti = values?.contentType else { continue }

            if types.contains(where: { uti.conforms(to: $0) }) {
                return true
            }
        }

        return false
    }
}

extension LSPService {
	/// Search the user's PATH for an executable
	public static func pathExecutableParamsProvider(name: String, processServiceHostName: String) async throws -> Process.ExecutionParameters {
		let userEnv = try await HostedProcess.userEnvironment(with: processServiceHostName)

		let whichParams = Process.ExecutionParameters(path: "/usr/bin/which", arguments: [name], environment: userEnv)

		let data = try await HostedProcess(named: processServiceHostName, parameters: whichParams)
			.runAndReadStdout()

		guard let output = String(data: data, encoding: .utf8) else {
			throw LSPServiceError.serverNotFound
		}

		if output.isEmpty {
			throw LSPServiceError.serverNotFound
		}

		let path = output.trimmingCharacters(in: .whitespacesAndNewlines)

		return .init(path: path, environment: userEnv)
	}
}
