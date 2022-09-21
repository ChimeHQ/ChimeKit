import Foundation
import os.log
import UniformTypeIdentifiers

import AnyCodable
import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol

public enum LSPServiceError: Error {
    case unsupported
	case providerUnavailable
    case noProjectConnection(URL)
    case noDocumentConnection(DocumentContext)
    case documentURLInvalid(DocumentContext)
}

/// Connect a language server to `ExtensionProtocol`.
public actor LSPService {
    public typealias ExecutionParamsProvider = () async throws -> Process.ExecutionParameters
	public typealias ContextFilter = (ProjectContext, DocumentContext?) async -> Bool

    private let serverOptions: any Codable
    private let executionParamsProvider: ExecutionParamsProvider
	private let contextFilter: ContextFilter
    private var projectServices: [URL: LSPProjectService]
    private let log: OSLog

    let host: HostProtocol
    let transformers: LSPTransformers

	/// The name of the XPC service used to launch and run the language server executable.
	public let processHostServiceName: String?

	/// Create an LSPService object.
	///
	/// - Parameter host: The `HostProtocol`-conforming object the service will communicate with.
	/// - Parameter serverOptions: A generic JSON object relayed to the language server as part of the initializatio procedure.
	/// - Parameter transformers: The structure of functions that is used to transformer the language server results to `ExtensionProtocol`-compatible types. Defaults to the standard transformers.
	/// - Parameter contextFilter: A function that determines which directories and files this server should interact with.
	/// - Parameter executionParamsProvider: A function that produces the configuration required to launch the language server executable.
	/// - Parameter processHostServiceName: The name of the XPC service used to launch and run the language server executable. Defaults to "com.chimehq.ChimeKit.ProcessService", which is bundled within ChimeKit.framework.
    public init(host: HostProtocol,
                serverOptions: any Codable = [:] as [String: String],
                transformers: LSPTransformers = .init(),
				contextFilter: @escaping ContextFilter,
                executionParamsProvider: @escaping ExecutionParamsProvider,
				processHostServiceName: String? = "com.chimehq.ChimeKit.ProcessService") {
        self.host = host
        self.transformers = transformers
        self.projectServices = [:]
        self.serverOptions = serverOptions
        self.executionParamsProvider = executionParamsProvider
		self.contextFilter = contextFilter
        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "LSPService")
		self.processHostServiceName = processHostServiceName
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
    public func didOpenProject(with context: ProjectContext) async throws {
        let url = context.url

        precondition(projectServices[url] == nil)

        let conn = LSPProjectService(context: context,
                                     host: host,
                                     serverOptions: serverOptions,
                                     transformers: transformers,
									 contextFilter: contextFilter,
                                     executionParamsProvider: executionParamsProvider,
									 processHostServiceName: processHostServiceName)

        self.projectServices[url] = conn
    }

    public func willCloseProject(with context: ProjectContext) async throws {
        let url = context.url
        let conn = projectServices[url]

        self.projectServices[url] = nil

        if let conn {
            try await conn.shutdown()
        }
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

extension LSPService {
    /// Produce a simple `ContextFilter` that examines file UTIs
    ///
    /// The returned function will return true if the supplied document conforms
    /// to one of the UTIs within `types`, or if the project root contains at least
    /// one conforming file.
    public static func contextFilter(for types: [UTType]) -> ContextFilter {
        return { (projectContext: ProjectContext, documentContext: DocumentContext?) async -> Bool in
            if let uti = documentContext?.uti {
                if types.contains(where: { uti.conforms(to: $0) }) {
                    return true
                }
            }

            return LSPService.projectRoot(at: projectContext.url, types: types)
        }
    }

    private static func projectRoot(at url: URL, types: [UTType]) -> Bool {
        let enumerator = FileManager.default.enumerator(at: url,
                                                        includingPropertiesForKeys: [.contentTypeKey],
                                                        options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])

        while let item = enumerator?.nextObject() as? URL {
            let values = try? item.resourceValues(forKeys: [.contentTypeKey])

            guard let uti = values?.contentType else { continue }

            if types.contains(where: { uti.conforms(to: $0) }) {
                return true
            }
        }

        return false
    }
}
