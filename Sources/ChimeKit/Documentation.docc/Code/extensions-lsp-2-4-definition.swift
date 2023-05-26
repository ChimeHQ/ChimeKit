import Foundation
import ChimeKit

public final class SwiftExtension {
    let host: any HostProtocol
    private let lspService: LSPService

    public init(host: any HostProtocol, processHostServiceName: String?) {
        self.host = host

        self.lspService = LSPService(host: host,
                                     executionParamsProvider: SwiftExtension.provideParams,
                                     processHostServiceName: processHostServiceName)
    }
}

extension SwiftExtension {
    private static func provideParams() throws -> Process.ExecutionParameters {
        return .init(path: "/usr/bin/sourcekit-lsp")
    }
}

extension SwiftExtension: ExtensionProtocol {
    public var configuration: ExtensionConfiguration {
        get async throws {
        }
    }

    public func didOpenProject(with context: ProjectContext) async throws {
    }

    public func willCloseProject(with context: ProjectContext) async throws {
    }

    public func symbolService(for context: ProjectContext) async throws -> SymbolQueryService? {
    }

    public func didOpenDocument(with context: DocumentContext) async throws -> URL? {
    }

    public func didChangeDocumentContext(from oldContext: DocumentContext, to newContext: DocumentContext) async throws {
    }

    public func willCloseDocument(with context: DocumentContext) async throws {
    }

    public func documentService(for context: DocumentContext) async throws -> DocumentService? {
    }
}
