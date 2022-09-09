import Foundation
import os.log

import AnyCodable
import ChimeExtensionInterface
import LanguageClient
import LanguageServerProtocol

public enum LSPServiceError: Error {
    case unsupported
    case noProjectConnection(URL)
    case noDocumentConnection(DocumentContext)
    case documentURLInvalid(DocumentContext)
}

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

    public init(host: HostProtocol,
                serverOptions: any Codable = [:] as [String: String],
                transformers: LSPTransformers = .init(),
				contextFilter: @escaping ContextFilter,
                executionParamsProvider: @escaping ExecutionParamsProvider) {
        self.host = host
        self.transformers = transformers
        self.projectServices = [:]
        self.serverOptions = serverOptions
        self.executionParamsProvider = executionParamsProvider
		self.contextFilter = contextFilter
        self.log = OSLog(subsystem: "com.chimehq.ChimeKit", category: "LSPService")
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
                                     executionParamsProvider: executionParamsProvider)

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
